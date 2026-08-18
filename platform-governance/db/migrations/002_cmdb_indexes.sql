CREATE INDEX idx_cmdb_assets_provider ON cmdb_assets(provider);
CREATE INDEX idx_cmdb_assets_criticality ON cmdb_assets(provider, revisionCount);
CREATE INDEX idx_cmdb_assets_scope ON cmdb_assets(accountOrSubscription, provider);
