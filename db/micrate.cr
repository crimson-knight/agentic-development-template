require "micrate"
require "pg"

# Micrate migration runner.
#
# Builds the connection URL exactly like config/database.cr: prefer DATABASE_URL,
# otherwise compose it from DB_* env vars with sensible local defaults (your
# shell user via `whoami`, localhost:5432). Deliberately does NOT read
# config/database.yml — that file uses ERB `<%= %>` which Crystal cannot parse.
#
# Usage (after `shards install`):
#   crystal build db/micrate.cr -o bin/micrate
#   bin/micrate up        # apply all pending migrations
#   bin/micrate down      # roll back the latest
#   bin/micrate status

app_env = ENV["APP_ENV"]? || ENV["AMBER_ENV"]? || "development"

Micrate::DB.connection_url = ENV["DATABASE_URL"]? || ENV["DATABASE_URI"]? || begin
  name = ENV["DB_NAME"]? || (app_env == "test" ? "agentc_app_template_oss_test" : "agentc_app_template_oss_development")
  host = ENV["DB_HOST"]? || "localhost"
  port = ENV["DB_PORT"]? || "5432"
  user = ENV["DB_USER"]? || `whoami`.strip
  pass = ENV["DB_PASSWORD"]?
  userinfo = (pass && !pass.empty?) ? "#{user}:#{pass}" : user
  "postgres://#{userinfo}@#{host}:#{port}/#{name}"
end

Micrate::Cli.run
