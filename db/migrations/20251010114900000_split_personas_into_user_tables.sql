-- +micrate Up
-- Split STI personas table into separate user tables for Grant ORM compatibility

CREATE TABLE IF NOT EXISTS regular_users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_digest VARCHAR(255) NOT NULL,
  last_login_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS admin_users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_digest VARCHAR(255) NOT NULL,
  api_key VARCHAR(255),
  api_secret VARCHAR(255),
  last_login_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_regular_users_email ON regular_users(email);
CREATE INDEX idx_admin_users_email ON admin_users(email);

-- Migrate existing data from personas table
INSERT INTO regular_users (id, email, password_digest, last_login_at, created_at, updated_at)
SELECT id, email, password_digest, last_login_at, created_at, updated_at
FROM personas
WHERE type = 'User';

INSERT INTO admin_users (id, email, password_digest, api_key, api_secret, last_login_at, created_at, updated_at)
SELECT id, email, password_digest, api_key, api_secret, last_login_at, created_at, updated_at
FROM personas
WHERE type = 'Admin';

-- Update sequences to avoid ID conflicts
SELECT setval('regular_users_id_seq', (SELECT COALESCE(MAX(id), 1) FROM regular_users));
SELECT setval('admin_users_id_seq', (SELECT COALESCE(MAX(id), 1) FROM admin_users));

-- Drop old personas table
DROP INDEX IF EXISTS idx_personas_email;
DROP TABLE IF EXISTS personas;

-- +micrate Down
-- Recreate personas table and migrate data back

CREATE TABLE IF NOT EXISTS personas (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  password_digest VARCHAR(255) NOT NULL,
  type VARCHAR(255) NOT NULL DEFAULT 'User',
  api_key VARCHAR(255) DEFAULT '',
  api_secret VARCHAR(255) DEFAULT '',
  last_login_at DATE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_personas_email ON personas(email);

-- Migrate data back from regular_users
INSERT INTO personas (id, email, password_digest, type, last_login_at, created_at, updated_at)
SELECT id, email, password_digest, 'User', last_login_at, created_at, updated_at
FROM regular_users;

-- Migrate data back from admin_users
INSERT INTO personas (id, email, password_digest, type, api_key, api_secret, last_login_at, created_at, updated_at)
SELECT id, email, password_digest, 'Admin', api_key, api_secret, last_login_at, created_at, updated_at
FROM admin_users;

-- Update sequence
SELECT setval('personas_id_seq', (SELECT COALESCE(MAX(id), 1) FROM personas));

-- Drop new tables
DROP INDEX IF EXISTS idx_regular_users_email;
DROP INDEX IF EXISTS idx_admin_users_email;
DROP TABLE IF EXISTS regular_users;
DROP TABLE IF EXISTS admin_users;
