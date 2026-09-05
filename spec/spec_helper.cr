ENV["AMBER_ENV"] ||= "test"

require "spec"
require "uri"

# Tests may delete fixture accounts. Never default to an application database.
fixture_database = URI.parse(ENV["DATABASE_URL"]? || "")
unless fixture_database.host == "127.0.0.1" && fixture_database.path == "/oss_owner_workspace_test_20260904_01"
  abort "Set DATABASE_URL to the dedicated local oss_owner_workspace_test_20260904_01 database."
end

require "../config/application"
Amber::Server.instance.handler.prepare_pipelines
require "../db/migrations/*"

Jennifer::Config.configure { |config| config.skip_dumping_schema_sql = true }
Jennifer::Migration::Runner.migrate
Spec.before_each { Persona.all.delete }

# Micrate::DB.connection_url = ENV["DATABASE_URL"]? || Amber.settings.database_url
# Automatically run migrations on the test database
# Micrate::Cli.run_up
