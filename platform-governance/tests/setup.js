const {
  createGovernanceRepository,
  createAuditLogger,
  createSsoClient,
  createProviderRegistry,
  createAuthorizationService,
  createExecutionService,
  createDiscoveryOrchestrator,
  createCmdbConsolidationService,
  createBaselineComparisonEngine,
  createM365BaselineImporter,
  createPolicyStateCollector,
  createCustomizationClassifier,
  createComplianceFindingGenerator,
  createDscVersionService,
  createDscControlRenderer,
  createDscProfileComposer,
  createTerraformAdvisoryValidator,
  createRefreshScheduler,
  createFreshnessAlerts,
} = require('../src/runtime/platform-governance');

const azure = require('../src/discovery/azure-discovery');
const aws = require('../src/discovery/aws-discovery');
const gcp = require('../src/discovery/gcp-discovery');

function createTestHarness() {
  const repository = createGovernanceRepository();
  const logger = createAuditLogger();
  const ssoClient = createSsoClient({ allowedTenants: ['tenant-1'] });
  const registry = createProviderRegistry({ azure, aws, gcp });
  const authorizationService = createAuthorizationService();
  const executionService = createExecutionService({ repository, ssoClient, authorizationService, logger });
  const discoveryOrchestrator = createDiscoveryOrchestrator({ registry, repository, logger });
  const cmdbConsolidationService = createCmdbConsolidationService({ repository, logger });
  const baselineComparisonEngine = createBaselineComparisonEngine();
  const m365BaselineImporter = createM365BaselineImporter();
  const policyStateCollector = createPolicyStateCollector();
  const customizationClassifier = createCustomizationClassifier();
  const complianceFindingGenerator = createComplianceFindingGenerator();
  const versionService = createDscVersionService();
  const controlRenderer = createDscControlRenderer();
  const dscProfileComposer = createDscProfileComposer({ versionService, controlRenderer });
  const terraformAdvisoryValidator = createTerraformAdvisoryValidator();
  const refreshScheduler = createRefreshScheduler();
  const freshnessAlerts = createFreshnessAlerts();

  return {
    repository,
    logger,
    ssoClient,
    registry,
    authorizationService,
    executionService,
    discoveryOrchestrator,
    cmdbConsolidationService,
    baselineComparisonEngine,
    m365BaselineImporter,
    policyStateCollector,
    customizationClassifier,
    complianceFindingGenerator,
    versionService,
    controlRenderer,
    dscProfileComposer,
    terraformAdvisoryValidator,
    refreshScheduler,
    freshnessAlerts,
  };
}

function buildAuthContext(overrides = {}) {
  return {
    tenantId: 'tenant-1',
    userId: 'user-1',
    token: 'token-1',
    scopes: ['platform:governance'],
    ...overrides,
  };
}

function buildExecutionInput(overrides = {}) {
  return {
    authContext: buildAuthContext(),
    targetPlatforms: ['azure', 'aws', 'gcp'],
    tenantScope: { tenantId: 'tenant-1' },
    ...overrides,
  };
}

module.exports = {
  createTestHarness,
  buildAuthContext,
  buildExecutionInput,
};
