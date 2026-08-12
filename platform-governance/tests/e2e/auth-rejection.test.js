const test = require('node:test');
const assert = require('node:assert/strict');
const { createTestHarness, buildAuthContext } = require('../setup');

test('invalid tenant is rejected before discovery', () => {
  const harness = createTestHarness();
  assert.throws(() => {
    harness.executionService.create({
      authContext: buildAuthContext({ tenantId: 'tenant-x' }),
      targetPlatforms: ['azure'],
      tenantScope: { tenantId: 'tenant-x' },
    });
  });
});
