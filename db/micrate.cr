require "micrate"
require "pg"
require "../config/database"

# Configure Micrate to use the same database connection as the app
Micrate::DB.connection_url = ENV["DATABASE_URL"]? || ENV["DATABASE_URI"]? || begin
  # If no DATABASE_URL, build from config/database.yml
  db_config = File.open("config/database.yml") do |file|
    YAML.parse(file)[APP_ENV]
  end
  
  database_name = db_config["database"]? ? db_config["database"].as_s : db_config["db"].as_s
  host = db_config["host"]? ? db_config["host"].as_s : "localhost"
  port = db_config["port"]? ? db_config["port"].as_i : 5432
  username = db_config["user"]? ? db_config["user"].as_s : "postgres"
  password = db_config["password"]? ? db_config["password"].as_s : ""
  
  "postgres://#{username}:#{password}@#{host}:#{port}/#{database_name}"
end

# Run the CLI
Micrate::Cli.run