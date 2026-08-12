const test = require('node:test');
const assert = require('node:assert/strict');
const { createTestHarness } = require('../setup');

test('baseline comparison emits structured results', () => {
  const harness = createTestHarness();
  const baselines = harness.m365BaselineImporter.importBaseline();
  const applied = harness.policyStateCollector.collect();
  const comparisons = harness.baselineComparisonEngine.compare(baselines, applied, []);
  assert.equal(comparisons.length, baselines.length);
  assert.ok(['compliant', 'non-compliant', 'not-applicable'].includes(comparisons[0].result));
});
