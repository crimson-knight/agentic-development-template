ENV["APP_ENV"] = "test"
ENV["AMBER_ENV"] = "test"
expected = ENV["AGENTC_TEST_DATABASE"]? || abort("Set AGENTC_TEST_DATABASE")
abort("Refusing a non-isolated database name") unless expected.matches?(/\Aagentc_android_[a-z0-9_]+\z/)
abort("Set an explicit DATABASE_URL") unless ENV["DATABASE_URL"]?
require "../config/application"
connection = Grant::Connections["pg"] || abort("Missing account database")
connection[:writer].open do |database|
  abort("Wrong task database") unless database.query_one("SELECT current_database()", as: String) == expected
end
# Synthetic reference account only, never included in the native application.
email = "native-emulator@example.test"
password = "Android-reference-only-2026!"
if user = Users::Regular.find_by(email: email)
  abort("Existing fixture has different credentials; not overwriting it") unless user.authenticate(password)
else
  user = Users::Regular.new
  user.email = email
  user.password = password
  abort("Could not create synthetic reference account") unless user.save
end
puts "PASS: isolated synthetic reference account is ready."
