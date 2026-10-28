PRAGMA foreign_keys = ON;

CREATE TABLE sources (
  id TEXT PRIMARY KEY,
  base_url TEXT NOT NULL,
  trust_level TEXT NOT NULL CHECK (trust_level IN ('A','B','C','D')),
  enabled INTEGER NOT NULL DEFAULT 0 CHECK (enabled IN (0,1)),
  policy_json TEXT NOT NULL CHECK (json_valid(policy_json))
);

CREATE TABLE consents (
  id TEXT PRIMARY KEY,
  actor_key TEXT NOT NULL,
  scope TEXT NOT NULL,
  scope_id TEXT NOT NULL,
  version INTEGER NOT NULL,
  granted_at INTEGER NOT NULL,
  revoked_at INTEGER,
  permissions_json TEXT NOT NULL CHECK (json_valid(permissions_json))
);

CREATE TABLE documents (
  id TEXT PRIMARY KEY,
  source_id TEXT NOT NULL REFERENCES sources(id),
  external_id TEXT NOT NULL,
  version TEXT NOT NULL,
  content_sha256 TEXT NOT NULL,
  scope TEXT NOT NULL,
  scope_id TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  deleted_at INTEGER,
  metadata_json TEXT NOT NULL CHECK (json_valid(metadata_json)),
  UNIQUE (source_id, external_id, version)
);

CREATE TABLE chunks (
  id TEXT PRIMARY KEY,
  document_id TEXT NOT NULL REFERENCES documents(id),
  parent_id TEXT REFERENCES chunks(id),
  content TEXT NOT NULL,
  search_text TEXT NOT NULL,
  token_count INTEGER NOT NULL CHECK (token_count >= 0),
  status TEXT NOT NULL,
  locator_json TEXT NOT NULL CHECK (json_valid(locator_json)),
  metadata_json TEXT NOT NULL CHECK (json_valid(metadata_json))
);

CREATE VIRTUAL TABLE chunks_fts USING fts5(
  chunk_id UNINDEXED,
  search_text,
  tokenize = 'unicode61'
);

CREATE TABLE knowledge_cards (
  id TEXT PRIMARY KEY,
  document_id TEXT NOT NULL REFERENCES documents(id),
  kind TEXT NOT NULL,
  content_json TEXT NOT NULL CHECK (json_valid(content_json)),
  evidence_ids_json TEXT NOT NULL CHECK (json_valid(evidence_ids_json)),
  review_status TEXT NOT NULL
);

CREATE TABLE memories (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL,
  scope TEXT NOT NULL,
  scope_id TEXT NOT NULL,
  subject TEXT NOT NULL,
  predicate TEXT NOT NULL,
  value_json TEXT NOT NULL CHECK (json_valid(value_json)),
  evidence_json TEXT NOT NULL CHECK (json_valid(evidence_json)),
  consent_id TEXT NOT NULL REFERENCES consents(id),
  confidence REAL NOT NULL CHECK (confidence BETWEEN 0 AND 1),
  status TEXT NOT NULL,
  valid_from INTEGER NOT NULL,
  valid_to INTEGER,
  expires_at INTEGER,
  supersedes_id TEXT REFERENCES memories(id)
);

CREATE UNIQUE INDEX memory_one_active_value
  ON memories(scope, scope_id, subject, predicate)
  WHERE status = 'active';

CREATE TABLE relations (
  id TEXT PRIMARY KEY,
  from_type TEXT NOT NULL,
  from_id TEXT NOT NULL,
  relation_type TEXT NOT NULL,
  to_type TEXT NOT NULL,
  to_id TEXT NOT NULL,
  metadata_json TEXT NOT NULL CHECK (json_valid(metadata_json))
);

CREATE TABLE jobs (
  id TEXT PRIMARY KEY,
  idempotency_key TEXT NOT NULL UNIQUE,
  kind TEXT NOT NULL,
  status TEXT NOT NULL,
  stage TEXT NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  next_run_at INTEGER NOT NULL,
  lease_until INTEGER,
  payload_json TEXT NOT NULL CHECK (json_valid(payload_json)),
  last_error_code TEXT
);

CREATE TABLE index_outbox (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_key TEXT NOT NULL UNIQUE,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  operation TEXT NOT NULL CHECK (operation IN ('upsert','delete')),
  generation INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  payload_json TEXT NOT NULL CHECK (json_valid(payload_json))
);

CREATE TABLE tombstones (
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  deletion_epoch INTEGER NOT NULL,
  deleted_at INTEGER NOT NULL,
  reason_code TEXT NOT NULL,
  PRIMARY KEY (entity_type, entity_id)
);

CREATE TABLE audit_events (
  id TEXT PRIMARY KEY,
  actor_key TEXT NOT NULL,
  action TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  details_json TEXT NOT NULL CHECK (json_valid(details_json))
);

CREATE INDEX documents_acl ON documents(scope, scope_id, status);
CREATE INDEX chunks_document_status ON chunks(document_id, status);
CREATE INDEX memories_acl ON memories(scope, scope_id, status, expires_at);
CREATE INDEX jobs_schedule ON jobs(status, next_run_at, lease_until);
CREATE INDEX outbox_pending ON index_outbox(status, id);
