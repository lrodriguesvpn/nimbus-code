const test = require('node:test');
const assert = require('node:assert/strict');
const { createTestHarness, buildExecutionInput } = require('../setup');

test('DSC profile versions increase monotonically', () => {
  const harness = createTestHarness();
  const execution = harness.executionService.create(buildExecutionInput());
  const baselines = harness.m365BaselineImporter.importBaseline();
  const first = harness.dscProfileComposer.compose({
    execution,
    baselines,
    findings: [],
    previousProfile: null,
  });
  const second = harness.dscProfileComposer.compose({
    execution,
    baselines,
    findings: [],
    previousProfile: first,
  });
  assert.notEqual(first.version, second.version);
});
