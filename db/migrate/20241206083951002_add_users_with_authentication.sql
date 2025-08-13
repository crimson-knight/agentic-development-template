-- +micrate Up
CREATE TABLE personas (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  password_digest VARCHAR(255) NOT NULL,
  type VARCHAR(255) NOT NULL DEFAULT 'User',
  api_key VARCHAR(255) DEFAULT '',
  api_secret VARCHAR(255) DEFAULT '',
  last_login_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE INDEX personas_email_idx ON personas(email);

-- +micrate Down
DROP TABLE IF EXISTS personas;