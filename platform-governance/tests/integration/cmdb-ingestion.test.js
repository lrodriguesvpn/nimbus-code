const test = require('node:test');
const assert = require('node:assert/strict');
const { createTestHarness, buildExecutionInput } = require('../setup');

test('multicloud discovery persists history and provenance', () => {
  const harness = createTestHarness();
  const execution = harness.executionService.create(buildExecutionInput());
  const first = harness.discoveryOrchestrator.run(execution);
  const second = harness.discoveryOrchestrator.run(execution);
  assert.ok(first.assets.length >= 3);
  assert.ok(second.assets.length >= 3);
  const history = harness.repository.getAssetHistory('azure:az-vm-001');
  assert.ok(history.length >= 2);
});
