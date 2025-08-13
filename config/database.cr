require "granite/adapter/pg"
require "yaml"

{% if @top_level.has_constant? "Spec" %}
  APP_ENV = "test"
{% else %}
  APP_ENV = ENV["APP_ENV"]? || "development"
{% end %}

database_url = ENV["DATABASE_URL"]? || ENV["DATABASE_URI"]?

if database_url
  Granite::Connections << Granite::Adapter::Pg.new(name: "pg", url: database_url)
else
  # Load from config/database.yml
  db_config = File.open("config/database.yml") do |file|
    YAML.parse(file)[APP_ENV]
  end
  
  # Support both 'database' and 'db' keys for compatibility
  database_name = db_config["database"]? ? db_config["database"].as_s : db_config["db"].as_s
  host = db_config["host"]? ? db_config["host"].as_s : "localhost"
  port = db_config["port"]? ? db_config["port"].as_i : 5432
  username = db_config["user"]? ? db_config["user"].as_s : "postgres"
  password = db_config["password"]? ? db_config["password"].as_s : ""
  
  Granite::Connections << Granite::Adapter::Pg.new(
    name: "pg",
    url: "postgres://#{username}:#{password}@#{host}:#{port}/#{database_name}"
  )
end