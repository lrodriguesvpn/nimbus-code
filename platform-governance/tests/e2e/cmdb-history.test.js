const test = require('node:test');
const assert = require('node:assert/strict');
const { createTestHarness, buildExecutionInput } = require('../setup');

test('repeat collection preserves asset history', () => {
  const harness = createTestHarness();
  const execution = harness.executionService.create(buildExecutionInput());
  harness.discoveryOrchestrator.run(execution);
  harness.discoveryOrchestrator.run(execution);
  const assets = harness.repository.listAssets({ provider: 'azure' });
  assert.ok(assets[0].revisionCount >= 2);
});
