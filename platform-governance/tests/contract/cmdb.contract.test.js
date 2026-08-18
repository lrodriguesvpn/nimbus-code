const test = require('node:test');
const assert = require('node:assert/strict');
const { createTestHarness, buildExecutionInput } = require('../setup');
const { isFreshCmdbRecord } = require('../../src/runtime/platform-governance');

test('CMDB records can be consolidated and evaluated for freshness', () => {
  const harness = createTestHarness();
  const execution = harness.executionService.create(buildExecutionInput());
  harness.discoveryOrchestrator.run(execution);
  const records = harness.cmdbConsolidationService.consolidate(execution.executionId);
  assert.ok(records.length > 0);
  assert.equal(isFreshCmdbRecord(records[0], 24), true);
});
