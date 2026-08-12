const { createFixtureDiscoveryAdapter } = require('../runtime/platform-governance');

module.exports = createFixtureDiscoveryAdapter('azure', [
  { assetId: 'az-vm-001', accountOrSubscription: 'sub-001', assetType: 'virtualMachine', displayName: 'vm-001' },
  { assetId: 'az-sql-001', accountOrSubscription: 'sub-001', assetType: 'sqlDatabase', displayName: 'sql-001' },
]);
