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
  createComplianceFindingGenerator,
  createDscVersionService,
  createDscControlRenderer,
  createDscProfileComposer,
  createTerraformAdvisoryValidator,
} = require('../runtime/platform-governance');

const azure = require('../discovery/azure-discovery');
const aws = require('../discovery/aws-discovery');
const gcp = require('../discovery/gcp-discovery');
const { initializeScope, resolveScope } = require('./commands/start-execution');

function createCliHarness() {
  const repository = createGovernanceRepository();
  const logger = createAuditLogger();
  const ssoClient = createSsoClient();
  const registry = createProviderRegistry({ azure, aws, gcp });
  const authorizationService = createAuthorizationService();
  const executionService = createExecutionService({ repository, ssoClient, authorizationService, logger });
  const discoveryOrchestrator = createDiscoveryOrchestrator({ registry, repository, logger });
  const cmdbConsolidationService = createCmdbConsolidationService({ repository, logger });
  const baselineComparisonEngine = createBaselineComparisonEngine();
  const complianceFindingGenerator = createComplianceFindingGenerator();
  const versionService = createDscVersionService();
  const controlRenderer = createDscControlRenderer();
  const dscProfileComposer = createDscProfileComposer({ versionService, controlRenderer });
  const terraformAdvisoryValidator = createTerraformAdvisoryValidator();
  return { repository, logger, executionService, discoveryOrchestrator, cmdbConsolidationService, baselineComparisonEngine, complianceFindingGenerator, dscProfileComposer, terraformAdvisoryValidator };
}

async function main(argv = process.argv.slice(2)) {
  const [command, ...args] = argv;
  const harness = createCliHarness();
  if (command === 'init') {
    return initializeScope(args);
  }
  if (command === 'validate') {
    const scope = resolveScope(args);
    const execution = harness.executionService.create({
      authContext: { tenantId: scope.tenantId, userId: 'cli-user', token: 'token-1' },
      targetPlatforms: scope.targetPlatforms,
      tenantScope: { tenantId: scope.tenantId },
    });
    const discovery = harness.discoveryOrchestrator.run(execution);
    const cmdbRecords = harness.cmdbConsolidationService.consolidate(execution.executionId);
    const baselines = harness.repository.listBaselines();
    const appliedStates = [];
    const comparisons = harness.baselineComparisonEngine.compare(baselines, appliedStates, []);
    const findings = harness.complianceFindingGenerator.generate(comparisons);
    const profile = harness.dscProfileComposer.compose({
      execution,
      baselines,
      findings,
      previousProfile: null,
    });
    const report = harness.terraformAdvisoryValidator.validate({
      cmdbRecords,
      findings,
      exceptions: [],
      terraformResources: [],
    });
    return { scope, execution, discovery, cmdbRecords, profile, report };
  }
  return { usage: 'init --providers azure[,aws,gcp] [--tenant tenant-id] | validate [--providers ...] [--tenant ...]' };
}

if (require.main === module) {
  main().then((result) => {
    if (result.usage) {
      console.log(result.usage);
      return;
    }
    console.log(JSON.stringify(result, null, 2));
  });
}

module.exports = { main, createCliHarness };
