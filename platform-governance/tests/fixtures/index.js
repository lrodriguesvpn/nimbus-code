module.exports = {
  tenantId: 'tenant-1',
  authContext: {
    tenantId: 'tenant-1',
    userId: 'user-1',
    token: 'token-1',
    scopes: ['platform:governance'],
  },
  execution: {
    targetPlatforms: ['azure', 'aws', 'gcp'],
    tenantScope: { tenantId: 'tenant-1' },
  },
};
