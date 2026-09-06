# Isolated web-regression entrypoint for the Android reference migration.
# This check executes before any application spec or its destructive hooks are
# registered. Never invoke the ordinary suite with an unverified ambient URL.
ENV["AMBER_ENV"] = "test"
ENV["APP_ENV"] = "test"
expected_database = ENV["AGENTC_TEST_DATABASE"]? || abort("Set AGENTC_TEST_DATABASE to the task-owned database name")
abort("Refusing a non-isolated database name") unless expected_database.matches?(/\Aagentc_android_[a-z0-9_]+\z/)
abort("Set an explicit DATABASE_URL for the isolated test database") unless ENV["DATABASE_URL"]?

require "spec"
require "../config/application"

connection = Grant::Connections["pg"] || abort("Missing application database connection")
connection[:writer].open do |database|
  actual = database.query_one("SELECT current_database()", as: String)
  abort("Application database does not match the isolated test target") unless actual == expected_database
end
puts "Verified isolated application database before registering web tests."

require "../spec/**"
