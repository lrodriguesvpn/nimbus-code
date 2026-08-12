const test = require('node:test');
const assert = require('node:assert/strict');
const { createTestHarness, buildExecutionInput } = require('../setup');

test('execution creation persists tenant scope', () => {
  const harness = createTestHarness();
  const execution = harness.executionService.create(buildExecutionInput());
  const saved = harness.repository.getExecution(execution.executionId);
  assert.equal(saved.tenantScope.tenantId, 'tenant-1');
  assert.equal(saved.requestedBy, 'user-1');
});
