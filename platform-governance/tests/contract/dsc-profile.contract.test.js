const test = require('node:test');
const assert = require('node:assert/strict');
const { createTestHarness, buildExecutionInput } = require('../setup');

test('DSC profile contains versioned desired controls', () => {
  const harness = createTestHarness();
  const execution = harness.executionService.create(buildExecutionInput());
  const baselines = harness.m365BaselineImporter.importBaseline();
  const profile = harness.dscProfileComposer.compose({
    execution,
    baselines,
    findings: [],
    previousProfile: null,
  });
  assert.equal(profile.scope.tenantRef, 'tenant-1');
  assert.ok(profile.version);
  assert.ok(Array.isArray(profile.desiredControls));
});
