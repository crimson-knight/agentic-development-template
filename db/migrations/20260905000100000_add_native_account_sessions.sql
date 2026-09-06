-- +micrate Up
ALTER TABLE regular_users ADD COLUMN display_name VARCHAR(256) NOT NULL DEFAULT '';
ALTER TABLE admin_users ADD COLUMN display_name VARCHAR(256) NOT NULL DEFAULT '';

CREATE TABLE native_account_sessions (
  token_digest CHAR(64) PRIMARY KEY,
  user_type VARCHAR(16) NOT NULL CHECK (user_type IN ('regular', 'admin')),
  user_id BIGINT NOT NULL,
  credential_fingerprint CHAR(64) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  last_seen_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  CHECK (expires_at > created_at)
);
CREATE INDEX native_account_sessions_owner ON native_account_sessions(user_type, user_id);
CREATE INDEX native_account_sessions_expiry ON native_account_sessions(expires_at);

-- +micrate Down
DROP TABLE native_account_sessions;
ALTER TABLE admin_users DROP COLUMN display_name;
ALTER TABLE regular_users DROP COLUMN display_name;
