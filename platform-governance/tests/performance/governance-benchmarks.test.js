const test = require('node:test');
const assert = require('node:assert/strict');
const { createTestHarness } = require('../setup');

test('refresh window flags stale environments', () => {
  const harness = createTestHarness();
  const result = harness.refreshScheduler.evaluate(['prod', 'dev'], {
    prod: new Date(Date.now() - 25 * 60 * 60 * 1000).toISOString(),
    dev: new Date().toISOString(),
  });
  assert.deepEqual(result.due, ['prod']);
});

test('freshness alerts reuse the same window logic', () => {
  const harness = createTestHarness();
  const misses = harness.freshnessAlerts.findMisses(['prod'], {});
  assert.deepEqual(misses, ['prod']);
});
