CREATE TABLE IF NOT EXISTS agents (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  token_hash TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  metrics_json TEXT
);

CREATE INDEX IF NOT EXISTS idx_agents_updated_at ON agents(updated_at DESC);
