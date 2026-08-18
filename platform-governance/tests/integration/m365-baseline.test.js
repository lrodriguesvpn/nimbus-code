const test = require('node:test');
const assert = require('node:assert/strict');
const { createTestHarness } = require('../setup');

test('M365 baseline import and comparison work together', () => {
  const harness = createTestHarness();
  const baselines = harness.m365BaselineImporter.importBaseline({ domains: ['identity', 'mail'] });
  const applied = harness.policyStateCollector.collect({ domains: ['identity', 'mail'], executionId: 'exec-1' });
  const comparisons = harness.baselineComparisonEngine.compare(baselines, applied, []);
  const findings = harness.complianceFindingGenerator.generate(comparisons);
  assert.equal(findings.length, 2);
});
