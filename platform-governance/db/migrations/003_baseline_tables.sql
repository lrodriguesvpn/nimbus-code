CREATE TABLE policy_baselines (
  baselineId TEXT PRIMARY KEY,
  domain TEXT NOT NULL,
  controlId TEXT NOT NULL,
  expectedState TEXT NOT NULL,
  severity TEXT NOT NULL,
  version TEXT NOT NULL,
  effectiveFrom TEXT NOT NULL,
  effectiveTo TEXT
);

CREATE TABLE applied_policy_state (
  appliedStateId TEXT PRIMARY KEY,
  domain TEXT NOT NULL,
  controlId TEXT NOT NULL,
  observedState TEXT NOT NULL,
  observedAt TEXT NOT NULL,
  sourceAssetRefs TEXT NOT NULL,
  sourceExecutionId TEXT NOT NULL
);

CREATE TABLE compliance_findings (
  findingId TEXT PRIMARY KEY,
  baselineId TEXT NOT NULL,
  appliedStateId TEXT,
  result TEXT NOT NULL,
  impact TEXT NOT NULL,
  recommendation TEXT NOT NULL,
  exceptionTicket TEXT,
  createdAt TEXT NOT NULL
);
