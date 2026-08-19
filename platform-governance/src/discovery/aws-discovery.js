const { createFixtureDiscoveryAdapter } = require('../runtime/platform-governance');

module.exports = createFixtureDiscoveryAdapter('aws', [
  { assetId: 'aws-ec2-001', accountOrSubscription: 'acct-001', assetType: 'ec2', displayName: 'ec2-001' },
  { assetId: 'aws-rds-001', accountOrSubscription: 'acct-001', assetType: 'rds', displayName: 'rds-001' },
]);
