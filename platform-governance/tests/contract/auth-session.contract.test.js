const test = require('node:test');
const assert = require('node:assert/strict');
const { createTestHarness, buildAuthContext } = require('../setup');

test('SSO bootstrap returns auditable session', () => {
  const harness = createTestHarness();
  const session = harness.ssoClient.bootstrapSession(buildAuthContext());
  assert.equal(session.tenantId, 'tenant-1');
  assert.equal(session.userId, 'user-1');
  assert.ok(session.sessionId);
});

test('execution creation requires valid SSO context', () => {
  const harness = createTestHarness();
  const execution = harness.executionService.create({
    authContext: buildAuthContext(),
    targetPlatforms: ['azure'],
    tenantScope: { tenantId: 'tenant-1' },
  });
  assert.equal(execution.status, 'pending');
  assert.deepEqual(execution.targetPlatforms, ['azure']);
});
