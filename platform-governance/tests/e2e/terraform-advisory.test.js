const test = require('node:test');
const assert = require('node:assert/strict');
const { createTestHarness } = require('../setup');

test('Terraform advisory validation returns evidence without blocking', () => {
  const harness = createTestHarness();
  const report = harness.terraformAdvisoryValidator.validate({
    cmdbRecords: [
      {
        canonicalAssetRef: 'azure:az-vm-001',
        evidenceRefs: ['azure:az-vm-001'],
      },
    ],
    findings: [
      {
        baselineId: 'b-1',
        appliedStateId: 'a-1',
        result: 'non-compliant',
        impact: 'high',
        recommendation: 'review',
      },
    ],
    exceptions: [],
    terraformResources: ['azurerm_linux_virtual_machine.example'],
  });
  assert.equal(report.nonConformities.length, 1);
  assert.equal(report.terraformResources.length, 1);
});
