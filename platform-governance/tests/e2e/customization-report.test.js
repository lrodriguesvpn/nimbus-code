const test = require('node:test');
const assert = require('node:assert/strict');
const { createTestHarness } = require('../setup');

test('customization classification and reporting produce findings', () => {
  const harness = createTestHarness();
  const exception = { exceptionId: 'exc-1', domain: 'identity', controlId: 'identity.default.1', status: 'approved' };
  const classification = harness.customizationClassifier.classify(exception);
  assert.equal(classification, 'approved');
  const findings = harness.complianceFindingGenerator.generate([
    {
      baseline: { baselineId: 'b-1', severity: 'high' },
      appliedState: { appliedStateId: 'a-1' },
      result: 'non-compliant',
      impact: 'high',
      recommendation: 'fix',
      exception,
    },
  ]);
  assert.equal(findings[0].exceptionTicket, 'exc-1');
});
