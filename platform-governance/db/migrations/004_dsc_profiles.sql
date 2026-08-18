CREATE TABLE dsc_profiles (
  profileId TEXT PRIMARY KEY,
  version TEXT NOT NULL,
  scope TEXT NOT NULL,
  desiredControls TEXT NOT NULL,
  derivedFromExecutionId TEXT NOT NULL,
  generatedAt TEXT NOT NULL,
  previousVersion TEXT,
  deltaSummary TEXT NOT NULL
);
