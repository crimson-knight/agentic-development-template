require "../config/database"
require "../src/models/**"
require "../db/migrations/*"

database = URI.parse(ENV["DATABASE_URL"]? || "")
unless database.host == "127.0.0.1" && database.path == "/oss_owner_workspace_browser_20260904_01"
  abort "Only the dedicated local OSS browser fixture database is allowed."
end
Jennifer::Config.configure { |config| config.skip_dumping_schema_sql = true }
Jennifer::Migration::Runner.migrate
email = "owner+long-test-identity-for-mobile@long-customer-domain.example.test"
abort "Fixture already exists; this script never resets accounts." if User.find_by({:email => email})
User.create!({email: email, password: "originalPassword123", password_confirmation: "originalPassword123", api_key: "", api_secret: ""})
puts "Local synthetic account created. No email was sent."
