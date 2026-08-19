CREATE TABLE executions (
  executionId TEXT PRIMARY KEY,
  requestedBy TEXT NOT NULL,
  authContextId TEXT NOT NULL,
  targetPlatforms TEXT NOT NULL,
  tenantScope TEXT NOT NULL,
  startedAt TEXT NOT NULL,
  finishedAt TEXT,
  status TEXT NOT NULL,
  advisoryMode INTEGER NOT NULL
);

CREATE TABLE cmdb_assets (
  assetKey TEXT PRIMARY KEY,
  provider TEXT NOT NULL,
  assetId TEXT NOT NULL,
  accountOrSubscription TEXT NOT NULL,
  assetType TEXT NOT NULL,
  displayName TEXT NOT NULL,
  sourceExecutionId TEXT NOT NULL,
  discoveredAt TEXT NOT NULL,
  revisionCount INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE audit_events (
  eventId TEXT PRIMARY KEY,
  traceId TEXT NOT NULL,
  spanId TEXT NOT NULL,
  service TEXT NOT NULL,
  level TEXT NOT NULL,
  event TEXT NOT NULL,
  payload TEXT NOT NULL,
  timestamp TEXT NOT NULL
);
