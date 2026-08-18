const http = require('node:http');
const { URL } = require('node:url');

function clone(value) {
  return value == null ? value : JSON.parse(JSON.stringify(value));
}

class GovernanceError extends Error {
  constructor(code, message, details) {
    super(message);
    this.name = this.constructor.name;
    this.code = code;
    this.details = details;
  }
}

class AuthError extends GovernanceError {
  constructor(message, details) {
    super('AUTH_ERROR', message, details);
  }
}

class DiscoveryError extends GovernanceError {
  constructor(message, details) {
    super('DISCOVERY_ERROR', message, details);
  }
}

class ValidationError extends GovernanceError {
  constructor(message, details) {
    super('VALIDATION_ERROR', message, details);
  }
}

class BaselineError extends GovernanceError {
  constructor(message, details) {
    super('BASELINE_ERROR', message, details);
  }
}

class DscError extends GovernanceError {
  constructor(message, details) {
    super('DSC_ERROR', message, details);
  }
}

function normalizeProviders(providers) {
  if (!Array.isArray(providers) || providers.length === 0) {
    throw new ValidationError('targetPlatforms must contain at least one provider');
  }
  const normalized = [...new Set(providers.map((provider) => String(provider).toLowerCase()))];
  const allowed = new Set(['azure', 'aws', 'gcp']);
  for (const provider of normalized) {
    if (!allowed.has(provider)) {
      throw new ValidationError(`unsupported provider: ${provider}`);
    }
  }
  return normalized;
}

function createExecutionContext(input) {
  const targetPlatforms = normalizeProviders(input.targetPlatforms);
  if (!input.authContextId) {
    throw new AuthError('authContextId is required before collection');
  }
  return {
    executionId: input.executionId || `exec-${Date.now()}`,
    requestedBy: input.requestedBy || 'unknown',
    authContextId: input.authContextId,
    targetPlatforms,
    tenantScope: input.tenantScope || {},
    startedAt: input.startedAt || new Date().toISOString(),
    finishedAt: input.finishedAt || null,
    status: input.status || 'pending',
    advisoryMode: input.advisoryMode !== false,
  };
}

function createCmdbRecord(input) {
  if (!input.canonicalAssetRef) {
    throw new ValidationError('canonicalAssetRef is required');
  }
  return {
    cmdbRecordId: input.cmdbRecordId || `cmdb-${Date.now()}`,
    canonicalAssetRef: input.canonicalAssetRef,
    providerFragments: clone(input.providerFragments || []),
    evidenceRefs: clone(input.evidenceRefs || []),
    lastConsolidatedAt: input.lastConsolidatedAt || new Date().toISOString(),
    dataQualityScore: input.dataQualityScore ?? 1,
    state: input.state || 'active',
  };
}

function isFreshCmdbRecord(record, maxHours = 24, now = new Date()) {
  const ageMs = now.getTime() - new Date(record.lastConsolidatedAt).getTime();
  return ageMs <= maxHours * 60 * 60 * 1000;
}

function createComplianceFinding(input) {
  return {
    findingId: input.findingId || `finding-${Date.now()}`,
    baselineId: input.baselineId,
    appliedStateId: input.appliedStateId,
    result: input.result,
    impact: input.impact,
    recommendation: input.recommendation,
    exceptionTicket: input.exceptionTicket || null,
    createdAt: input.createdAt || new Date().toISOString(),
  };
}

function createSsoClient(config = {}) {
  return {
    bootstrapSession(context) {
      if (!context || !context.tenantId || !context.userId || !context.token) {
        throw new AuthError('invalid SSO context');
      }
      if (Array.isArray(config.allowedTenants) && config.allowedTenants.length > 0 && !config.allowedTenants.includes(context.tenantId)) {
        throw new AuthError('tenant not allowed');
      }
      return {
        sessionId: context.sessionId || `sso-${Date.now()}`,
        tenantId: context.tenantId,
        userId: context.userId,
        scopes: clone(context.scopes || []),
        issuedAt: context.issuedAt || new Date().toISOString(),
      };
    },
    validateSession(session) {
      if (!session || !session.sessionId) {
        throw new AuthError('missing session');
      }
      return true;
    },
  };
}

function createProviderRegistry(adapters = {}) {
  const registry = new Map(Object.entries(adapters));
  return {
    registerAdapter(provider, adapter) {
      registry.set(String(provider).toLowerCase(), adapter);
    },
    getAdapter(provider) {
      const adapter = registry.get(String(provider).toLowerCase());
      if (!adapter) {
        throw new DiscoveryError(`no discovery adapter for provider: ${provider}`);
      }
      return adapter;
    },
    listProviders() {
      return [...registry.keys()];
    },
  };
}

function createAuditLogger(store = []) {
  return {
    log(entry) {
      const value = {
        trace_id: entry.trace_id || entry.traceId || `trace-${Date.now()}`,
        span_id: entry.span_id || entry.spanId || `span-${Date.now()}`,
        service: entry.service || 'platform-governance',
        level: entry.level || 'info',
        event: entry.event,
        timestamp: entry.timestamp || new Date().toISOString(),
        payload: clone(entry.payload || {}),
      };
      store.push(value);
      return value;
    },
    entries() {
      return clone(store);
    },
  };
}

function createGovernanceRepository(initial = {}) {
  const state = {
    executions: new Map(),
    assets: new Map(),
    assetHistory: new Map(),
    relationships: [],
    baselines: new Map(),
    appliedStates: new Map(),
    findings: new Map(),
    exceptions: new Map(),
    dscProfiles: new Map(),
    audit: [],
  };

  const seed = clone(initial);
  for (const execution of seed.executions || []) state.executions.set(execution.executionId, execution);
  for (const asset of seed.assets || []) state.assets.set(asset.assetKey || asset.assetId, asset);
  for (const baseline of seed.baselines || []) state.baselines.set(baseline.baselineId, baseline);
  for (const appliedState of seed.appliedStates || []) state.appliedStates.set(appliedState.appliedStateId, appliedState);
  for (const finding of seed.findings || []) state.findings.set(finding.findingId, finding);
  for (const exception of seed.exceptions || []) state.exceptions.set(exception.exceptionId, exception);
  for (const profile of seed.dscProfiles || []) state.dscProfiles.set(profile.profileId, profile);
  state.audit.push(...(seed.audit || []));

  function putAsset(asset) {
    const assetKey = `${asset.provider}:${asset.assetId}`;
    const history = state.assetHistory.get(assetKey) || [];
    history.push(clone({ ...asset, assetKey }));
    state.assetHistory.set(assetKey, history);
    state.assets.set(assetKey, { ...clone(asset), assetKey, revisionCount: history.length });
    return state.assets.get(assetKey);
  }

  return {
    saveExecution(execution) {
      state.executions.set(execution.executionId, clone(execution));
      return clone(execution);
    },
    getExecution(executionId) {
      return clone(state.executions.get(executionId));
    },
    listExecutions() {
      return clone([...state.executions.values()]);
    },
    upsertAsset(asset) {
      if (!asset.provider || !asset.assetId) {
        throw new ValidationError('asset provider and assetId are required');
      }
      return clone(putAsset(asset));
    },
    listAssets(filter = {}) {
      const assets = [...state.assets.values()];
      return clone(assets.filter((asset) => {
        if (filter.provider && asset.provider !== filter.provider) return false;
        if (filter.criticality && asset.securityCriticality !== filter.criticality) return false;
        if (filter.executionId && asset.sourceExecutionId !== filter.executionId) return false;
        if (filter.scope && filter.scope.tenantId && asset.accountOrSubscription !== filter.scope.tenantId) return false;
        return true;
      }));
    },
    getAssetHistory(assetKey) {
      return clone(state.assetHistory.get(assetKey) || []);
    },
    saveRelationship(relationship) {
      state.relationships.push(clone(relationship));
      return clone(relationship);
    },
    listRelationships() {
      return clone(state.relationships);
    },
    saveBaseline(baseline) {
      state.baselines.set(baseline.baselineId, clone(baseline));
      return clone(baseline);
    },
    listBaselines() {
      return clone([...state.baselines.values()]);
    },
    saveAppliedState(appliedState) {
      state.appliedStates.set(appliedState.appliedStateId, clone(appliedState));
      return clone(appliedState);
    },
    listAppliedStates() {
      return clone([...state.appliedStates.values()]);
    },
    saveFinding(finding) {
      state.findings.set(finding.findingId, clone(finding));
      return clone(finding);
    },
    listFindings() {
      return clone([...state.findings.values()]);
    },
    saveException(exception) {
      state.exceptions.set(exception.exceptionId, clone(exception));
      return clone(exception);
    },
    listExceptions() {
      return clone([...state.exceptions.values()]);
    },
    saveDscProfile(profile) {
      state.dscProfiles.set(profile.profileId, clone(profile));
      return clone(profile);
    },
    listDscProfiles() {
      return clone([...state.dscProfiles.values()]);
    },
    appendAudit(entry) {
      state.audit.push(clone(entry));
      return clone(entry);
    },
    listAudit() {
      return clone(state.audit);
    },
    snapshot() {
      return {
        executions: this.listExecutions(),
        assets: this.listAssets(),
        relationships: this.listRelationships(),
        baselines: this.listBaselines(),
        appliedStates: this.listAppliedStates(),
        findings: this.listFindings(),
        exceptions: this.listExceptions(),
        dscProfiles: this.listDscProfiles(),
        audit: this.listAudit(),
      };
    },
  };
}

function compareVersions(left, right) {
  const l = String(left || '0.0.0').split('.').map(Number);
  const r = String(right || '0.0.0').split('.').map(Number);
  for (let index = 0; index < 3; index += 1) {
    const diff = (l[index] || 0) - (r[index] || 0);
    if (diff !== 0) return diff;
  }
  return 0;
}

function nextVersion(version) {
  const parts = String(version || '1.0.0').split('.').map((part) => Number(part) || 0);
  if (parts.length !== 3) {
    return '1.0.0';
  }
  parts[2] += 1;
  return parts.join('.');
}

function validateMonotonicVersion(previousVersion, nextVersionValue) {
  if (compareVersions(nextVersionValue, previousVersion) <= 0) {
    throw new ValidationError('version must increase monotonically');
  }
  return true;
}

function inferRelationships(assets) {
  const relationships = [];
  for (let i = 0; i < assets.length; i += 1) {
    for (let j = i + 1; j < assets.length; j += 1) {
      const left = assets[i];
      const right = assets[j];
      if (left.provider === right.provider && left.accountOrSubscription === right.accountOrSubscription) {
        relationships.push({
          relationshipId: `rel-${left.assetId}-${right.assetId}`,
          fromAssetId: left.assetId,
          toAssetId: right.assetId,
          relationshipType: 'shared-account',
          confidenceScore: 0.8,
          observedAt: new Date().toISOString(),
        });
      }
    }
  }
  return relationships;
}

function createFixtureDiscoveryAdapter(provider, assets) {
  return {
    provider,
    discover({ execution }) {
      return {
        assets: assets.map((asset, index) => ({
          ...clone(asset),
          provider,
          assetId: asset.assetId || `${provider}-${index + 1}`,
          sourceExecutionId: execution.executionId,
          discoveredAt: new Date().toISOString(),
        })),
        relationships: inferRelationships(assets),
        evidence: assets.map((asset) => ({
          sourceAssetRef: `${provider}:${asset.assetId}`,
          sourceExecutionId: execution.executionId,
          capturedAt: new Date().toISOString(),
        })),
      };
    },
  };
}

function createDiscoveryOrchestrator({ registry, repository, logger }) {
  return {
    run(execution) {
      if (!execution || !execution.executionId) {
        throw new DiscoveryError('execution is required');
      }
      const allAssets = [];
      const allRelationships = [];
      const allEvidence = [];
      for (const provider of execution.targetPlatforms) {
        const adapter = registry.getAdapter(provider);
        const result = adapter.discover({ execution });
        for (const asset of result.assets || []) {
          allAssets.push(repository.upsertAsset(asset));
        }
        for (const relationship of result.relationships || []) {
          allRelationships.push(repository.saveRelationship({ ...relationship, provider }));
        }
        allEvidence.push(...(result.evidence || []));
      }
      const payload = {
        executionId: execution.executionId,
        assets: allAssets,
        relationships: allRelationships,
        evidence: allEvidence,
      };
      logger.log({ event: 'discovery_completed', payload });
      return payload;
    },
  };
}

function createCmdbConsolidationService({ repository, logger }) {
  return {
    consolidate(executionId) {
      const assets = repository.listAssets({ executionId });
      const records = assets.map((asset) =>
        createCmdbRecord({
          canonicalAssetRef: `${asset.provider}:${asset.assetId}`,
          providerFragments: [asset],
          evidenceRefs: [`${asset.provider}:${asset.assetId}`],
          lastConsolidatedAt: new Date().toISOString(),
          dataQualityScore: 1,
          state: 'active',
        })
      );
      for (const record of records) {
        repository.saveBaseline({
          baselineId: `baseline-${record.canonicalAssetRef}`,
          domain: 'inventory',
          controlId: record.canonicalAssetRef,
          expectedState: { managed: true },
          severity: 'low',
          version: '1.0.0',
          effectiveFrom: new Date().toISOString().slice(0, 10),
        });
      }
      logger.log({ event: 'cmdb_consolidated', payload: { executionId, count: records.length } });
      return records;
    },
  };
}

function createEvidenceService({ repository }) {
  return {
    record(provenance) {
      const entry = {
        sourceAssetRef: provenance.sourceAssetRef,
        sourceExecutionId: provenance.sourceExecutionId,
        capturedAt: provenance.capturedAt || new Date().toISOString(),
      };
      repository.appendAudit({ event: 'evidence_recorded', payload: entry });
      return entry;
    },
  };
}

function createAuthorizationService({ allowedProviders = ['azure', 'aws', 'gcp'] } = {}) {
  return {
    authorize(selection) {
      const requested = normalizeProviders(selection.targetPlatforms);
      const denied = requested.filter((provider) => !allowedProviders.includes(provider));
      if (denied.length > 0) {
        throw new AuthError(`providers not allowed: ${denied.join(', ')}`);
      }
      return {
        ...selection,
        targetPlatforms: requested,
      };
    },
  };
}

function createExecutionService({ repository, ssoClient, authorizationService, logger }) {
  return {
    create(input) {
      const session = ssoClient.bootstrapSession(input.authContext);
      const authorized = authorizationService.authorize({
        targetPlatforms: input.targetPlatforms,
        tenantScope: input.tenantScope || {},
      });
      const execution = createExecutionContext({
        executionId: input.executionId,
        requestedBy: session.userId,
        authContextId: session.sessionId,
        targetPlatforms: authorized.targetPlatforms,
        tenantScope: authorized.tenantScope,
        advisoryMode: input.advisoryMode,
      });
      repository.saveExecution(execution);
      logger.log({ event: 'execution_created', payload: { executionId: execution.executionId } });
      return execution;
    },
    start(executionId) {
      const execution = repository.getExecution(executionId);
      if (!execution) {
        throw new ValidationError(`execution not found: ${executionId}`);
      }
      execution.status = 'running';
      repository.saveExecution(execution);
      logger.log({ event: 'execution_started', payload: { executionId } });
      return execution;
    },
  };
}

function createBaselineRepositoryView(repository) {
  return {
    listBaselines: () => repository.listBaselines(),
    listAppliedStates: () => repository.listAppliedStates(),
    listFindings: () => repository.listFindings(),
    listExceptions: () => repository.listExceptions(),
  };
}

function createM365BaselineImporter() {
  return {
    importBaseline(scope = {}) {
      const domains = scope.domains || ['identity', 'mail', 'device', 'compliance'];
      return domains.map((domain, index) => ({
        baselineId: `m365-${domain}-${index + 1}`,
        domain,
        controlId: `${domain}.default.${index + 1}`,
        expectedState: { enforced: true },
        severity: index === 0 ? 'critical' : 'medium',
        version: '1.0.0',
        effectiveFrom: new Date().toISOString().slice(0, 10),
      }));
    },
  };
}

function createPolicyStateCollector() {
  return {
    collect(scope = {}) {
      const domains = scope.domains || ['identity', 'mail', 'device', 'compliance'];
      return domains.map((domain, index) => ({
        appliedStateId: `applied-${domain}-${index + 1}`,
        domain,
        controlId: `${domain}.default.${index + 1}`,
        observedState: { enforced: index % 2 === 0 },
        observedAt: new Date().toISOString(),
        sourceAssetRefs: [`m365:${domain}`],
        sourceExecutionId: scope.executionId || 'unknown',
      }));
    },
  };
}

function createBaselineComparisonEngine() {
  return {
    compare(baselines, appliedStates, exceptions = []) {
      const byKey = new Map(appliedStates.map((state) => [`${state.domain}:${state.controlId}`, state]));
      const exceptionByKey = new Map(exceptions.map((exception) => [`${exception.domain}:${exception.controlId}`, exception]));
      return baselines.map((baseline) => {
        const key = `${baseline.domain}:${baseline.controlId}`;
        const applied = byKey.get(key);
        if (!applied) {
          return {
            baseline,
            appliedState: null,
            result: 'not-applicable',
            impact: baseline.severity,
            recommendation: 'collect tenant state before comparison',
          };
        }
        const compliant = JSON.stringify(applied.observedState) === JSON.stringify(baseline.expectedState);
        const exception = exceptionByKey.get(key);
        return {
          baseline,
          appliedState: applied,
          result: compliant ? 'compliant' : 'non-compliant',
          impact: baseline.severity,
          recommendation: compliant ? 'none' : `align ${baseline.controlId} with baseline`,
          exception,
        };
      });
    },
  };
}

function createCustomizationClassifier() {
  return {
    classify(exception) {
      if (!exception) return 'none';
      if (exception.status === 'approved') return 'approved';
      if (exception.status === 'rejected') return 'rejected';
      if (exception.expiresAt && new Date(exception.expiresAt).getTime() <= Date.now()) return 'expired';
      return 'pending';
    },
  };
}

function createComplianceFindingGenerator() {
  return {
    generate(comparisons) {
      return comparisons.map((comparison) =>
        createComplianceFinding({
          baselineId: comparison.baseline.baselineId,
          appliedStateId: comparison.appliedState ? comparison.appliedState.appliedStateId : null,
          result: comparison.result,
          impact: comparison.impact,
          recommendation: comparison.recommendation,
          exceptionTicket: comparison.exception ? comparison.exception.exceptionId : null,
        })
      );
    },
  };
}

function createBaselineEvidenceLinker() {
  return {
    link(findings, cmdbRecords) {
      const recordRefs = new Map(cmdbRecords.map((record) => [record.canonicalAssetRef, record]));
      return findings.map((finding) => {
        const linkedRecord = recordRefs.values().next().value || null;
        return {
          ...finding,
          evidenceRefs: linkedRecord ? linkedRecord.evidenceRefs : [],
        };
      });
    },
  };
}

function createDscControlRenderer() {
  return {
    render(baselines) {
      return baselines.map((baseline) => ({
        domain: baseline.domain,
        controlId: baseline.controlId,
        expectedState: baseline.expectedState,
        severity: baseline.severity,
      }));
    },
  };
}

function createDscVersionService() {
  return {
    next(previousProfile, scopeKey) {
      const previousVersion = previousProfile?.version || '1.0.0';
      const version = nextVersion(previousVersion);
      if (previousProfile) {
        validateMonotonicVersion(previousVersion, version);
      }
      return {
        version,
        scopeKey: scopeKey || 'default',
      };
    },
  };
}

function createDscProfileComposer({ versionService, controlRenderer }) {
  return {
    compose({ execution, baselines, findings, previousProfile }) {
      const controls = controlRenderer.render(baselines);
      const version = versionService.next(previousProfile, execution?.tenantScope?.tenantId || 'default');
      return {
        profileId: `dsc-${execution.executionId}`,
        version: version.version,
        scope: {
          providers: execution.targetPlatforms,
          tenantRef: execution.tenantScope?.tenantId || 'default',
        },
        desiredControls: controls,
        derivedFromExecutionId: execution.executionId,
        generatedAt: new Date().toISOString(),
        previousVersion: previousProfile ? previousProfile.version : null,
        deltaSummary: findings.filter((finding) => finding.result !== 'compliant').map((finding) => finding.recommendation).join('; ') || 'no delta',
      };
    },
  };
}

function createTerraformAdvisoryValidator() {
  return {
    validate({ cmdbRecords, findings, exceptions, terraformResources = [] }) {
      const approvedExceptions = new Set(
        (exceptions || [])
          .filter((exception) => exception.status === 'approved')
          .map((exception) => exception.baselineId || exception.controlId || exception.exceptionId)
      );
      const nonCompliant = findings.filter((finding) => finding.result !== 'compliant');
      return {
        conformities: findings.filter((finding) => finding.result === 'compliant'),
        nonConformities: nonCompliant.map((finding) => ({
          ...finding,
          exceptionRequired: !approvedExceptions.has(finding.baselineId),
        })),
        recommendations: nonCompliant.map((finding) => finding.recommendation),
        terraformResources,
        cmdbRecordsCount: cmdbRecords.length,
      };
    },
  };
}

function createCmdbExportService(repository) {
  return {
    exportInventory(filter = {}) {
      return repository.listAssets(filter).map((asset) => ({
        provider: asset.provider,
        assetId: asset.assetId,
        assetType: asset.assetType,
        displayName: asset.displayName,
        criticality: asset.securityCriticality || 'medium',
        sourceExecutionId: asset.sourceExecutionId,
      }));
    },
  };
}

function createRefreshScheduler() {
  return {
    evaluate(environments, lastCompletedAtByEnvironment, maxHours = 24) {
      const due = [];
      const missed = [];
      for (const environment of environments) {
        const timestamp = lastCompletedAtByEnvironment[environment];
        if (!timestamp) {
          missed.push(environment);
          continue;
        }
        const fresh = isFreshCmdbRecord({ lastConsolidatedAt: timestamp }, maxHours);
        if (!fresh) due.push(environment);
      }
      return { due, missed, maxHours };
    },
  };
}

function createFreshnessAlerts() {
  return {
    findMisses(environments, lastCompletedAtByEnvironment, maxHours = 24) {
      const evaluation = createRefreshScheduler().evaluate(environments, lastCompletedAtByEnvironment, maxHours);
      return [...evaluation.due, ...evaluation.missed];
    },
  };
}

function createGovernanceApi({ repository, executionService, discoveryOrchestrator, cmdbConsolidationService, baselineComparisonEngine, complianceFindingGenerator, dscProfileComposer, terraformAdvisoryValidator, ssoClient, logger }) {
  function sendJson(res, statusCode, body) {
    res.writeHead(statusCode, { 'content-type': 'application/json' });
    res.end(JSON.stringify(body));
  }

  return async function handler(req, res) {
    const url = new URL(req.url, 'http://localhost');
    const chunks = [];
    for await (const chunk of req) chunks.push(chunk);
    const rawBody = Buffer.concat(chunks).toString('utf8') || '{}';
    const body = rawBody ? JSON.parse(rawBody) : {};

    if (req.method === 'GET' && url.pathname === '/health') {
      return sendJson(res, 200, { ok: true });
    }
    if (req.method === 'POST' && url.pathname === '/auth/sso/session') {
      const session = ssoClient.bootstrapSession(body);
      return sendJson(res, 200, session);
    }
    if (req.method === 'POST' && url.pathname === '/executions') {
      const execution = executionService.create(body);
      return sendJson(res, 201, execution);
    }
    if (req.method === 'POST' && url.pathname.startsWith('/executions/') && url.pathname.endsWith('/run')) {
      const executionId = url.pathname.split('/')[2];
      const execution = executionService.start(executionId);
      const discovery = discoveryOrchestrator.run(execution);
      const cmdbRecords = cmdbConsolidationService.consolidate(execution.executionId);
      return sendJson(res, 202, { execution, discovery, cmdbRecords });
    }
    if (req.method === 'GET' && url.pathname === '/cmdb/records') {
      return sendJson(res, 200, repository.listAssets({ provider: url.searchParams.get('provider') || undefined }));
    }
    if (req.method === 'POST' && url.pathname === '/baselines/compare') {
      const comparisons = baselineComparisonEngine.compare(body.baselines || [], body.appliedStates || [], body.exceptions || []);
      const findings = complianceFindingGenerator.generate(comparisons);
      for (const finding of findings) repository.saveFinding(finding);
      return sendJson(res, 200, { comparisons, findings });
    }
    if (req.method === 'GET' && url.pathname === '/compliance/findings') {
      return sendJson(res, 200, repository.listFindings());
    }
    if (req.method === 'POST' && url.pathname === '/dsc/profiles') {
      const profile = dscProfileComposer.compose(body);
      repository.saveDscProfile(profile);
      return sendJson(res, 201, profile);
    }
    if (req.method === 'POST' && url.pathname === '/governance/terraform/validate') {
      const report = terraformAdvisoryValidator.validate(body);
      return sendJson(res, 200, report);
    }

    logger.log({ level: 'warning', event: 'route_not_found', payload: { method: req.method, path: url.pathname } });
    return sendJson(res, 404, { error: 'not_found' });
  };
}

function startGovernanceServer(options = {}) {
  const repository = options.repository || createGovernanceRepository();
  const logger = options.logger || createAuditLogger(repository.listAudit());
  const ssoClient = options.ssoClient || createSsoClient(options.auth || {});
  const registry = options.registry || createProviderRegistry(options.adapters || {});
  const authorizationService = options.authorizationService || createAuthorizationService(options.authorization || {});
  const executionService = options.executionService || createExecutionService({
    repository,
    ssoClient,
    authorizationService,
    logger,
  });
  const discoveryOrchestrator = options.discoveryOrchestrator || createDiscoveryOrchestrator({ registry, repository, logger });
  const cmdbConsolidationService = options.cmdbConsolidationService || createCmdbConsolidationService({ repository, logger });
  const baselineComparisonEngine = options.baselineComparisonEngine || createBaselineComparisonEngine();
  const complianceFindingGenerator = options.complianceFindingGenerator || createComplianceFindingGenerator();
  const versionService = options.versionService || createDscVersionService();
  const controlRenderer = options.controlRenderer || createDscControlRenderer();
  const dscProfileComposer = options.dscProfileComposer || createDscProfileComposer({ versionService, controlRenderer });
  const terraformAdvisoryValidator = options.terraformAdvisoryValidator || createTerraformAdvisoryValidator();
  const handler = createGovernanceApi({
    repository,
    executionService,
    discoveryOrchestrator,
    cmdbConsolidationService,
    baselineComparisonEngine,
    complianceFindingGenerator,
    dscProfileComposer,
    terraformAdvisoryValidator,
    ssoClient,
    logger,
  });
  const server = http.createServer(handler);
  return { server, repository, registry, executionService, handler };
}

module.exports = {
  clone,
  AuthError,
  DiscoveryError,
  ValidationError,
  BaselineError,
  DscError,
  createExecutionContext,
  createCmdbRecord,
  isFreshCmdbRecord,
  createComplianceFinding,
  createSsoClient,
  createProviderRegistry,
  createAuditLogger,
  createGovernanceRepository,
  compareVersions,
  nextVersion,
  validateMonotonicVersion,
  createFixtureDiscoveryAdapter,
  inferRelationships,
  createDiscoveryOrchestrator,
  createCmdbConsolidationService,
  createEvidenceService,
  createAuthorizationService,
  createExecutionService,
  createM365BaselineImporter,
  createPolicyStateCollector,
  createBaselineComparisonEngine,
  createCustomizationClassifier,
  createComplianceFindingGenerator,
  createBaselineEvidenceLinker,
  createDscControlRenderer,
  createDscVersionService,
  createDscProfileComposer,
  createTerraformAdvisoryValidator,
  createCmdbExportService,
  createRefreshScheduler,
  createFreshnessAlerts,
  createGovernanceApi,
  startGovernanceServer,
};
