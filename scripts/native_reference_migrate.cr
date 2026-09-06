require "pg"
require "micrate"

# Only the task-owned reference database is eligible. This script deliberately
# offers no rollback/drop mode and never falls back to an ambient development DB.
expected = ENV["AGENTC_TEST_DATABASE"]? || abort("Set AGENTC_TEST_DATABASE")
abort("Refusing a non-isolated database name") unless expected.matches?(/\Aagentc_android_[a-z0-9_]+\z/)
url = ENV["DATABASE_URL"]? || abort("Set an explicit DATABASE_URL")
DB.open(url) do |database|
  actual = database.query_one("SELECT current_database()", as: String)
  abort("Database does not match the isolated task target") unless actual == expected
  puts "Verified isolated database before forward migrations."
  result = Micrate.up(database)
  abort("Migration did not complete successfully") unless result == :success || result == :nop
end
