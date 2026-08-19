const test = require('node:test');
const assert = require('node:assert/strict');
const { createTestHarness, buildExecutionInput } = require('../setup');

test('smoke flow auth -> CMDB -> baseline -> DSC works', () => {
  const harness = createTestHarness();
  const execution = harness.executionService.create(buildExecutionInput());
  const discovery = harness.discoveryOrchestrator.run(execution);
  const cmdbRecords = harness.cmdbConsolidationService.consolidate(execution.executionId);
  const baselines = harness.m365BaselineImporter.importBaseline();
  const applied = harness.policyStateCollector.collect({ executionId: execution.executionId });
  const comparisons = harness.baselineComparisonEngine.compare(baselines, applied, []);
  const findings = harness.complianceFindingGenerator.generate(comparisons);
  const profile = harness.dscProfileComposer.compose({
    execution,
    baselines,
    findings,
    previousProfile: null,
  });

  assert.ok(discovery.assets.length > 0);
  assert.ok(cmdbRecords.length > 0);
  assert.equal(profile.scope.tenantRef, 'tenant-1');
});
