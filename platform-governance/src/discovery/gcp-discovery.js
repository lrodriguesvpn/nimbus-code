const { createFixtureDiscoveryAdapter } = require('../runtime/platform-governance');

module.exports = createFixtureDiscoveryAdapter('gcp', [
  { assetId: 'gcp-vm-001', accountOrSubscription: 'proj-001', assetType: 'computeInstance', displayName: 'vm-001' },
  { assetId: 'gcp-sql-001', accountOrSubscription: 'proj-001', assetType: 'cloudSql', displayName: 'sql-001' },
]);
