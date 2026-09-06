require "pg"
require "grant"
require "grant/adapter/pg"
# Grant's locking module references all adapters, so we need to require them
# even if we're only using PostgreSQL
require "grant/adapter/mysql"
require "grant/adapter/sqlite"
require "yaml"

{% if @top_level.has_constant? "Spec" %}
  APP_ENV = "test"
{% else %}
  APP_ENV = ENV["APP_ENV"]? || "development"
{% end %}

database_url = ENV["DATABASE_URL"]? || ENV["DATABASE_URI"]?

if database_url
  Grant::Connections << Grant::Adapter::Pg.new(name: "pg", url: database_url)
else
  # Use ENV variables first, fall back to defaults
  database_name = ENV["DB_NAME"]? || (APP_ENV == "test" ? "agentc_app_template_oss_test" : "agentc_app_template_oss_development")
  host = ENV["DB_HOST"]? || "localhost"
  port = ENV["DB_PORT"]?.try(&.to_i) || 5432
  username = ENV["DB_USER"]? || `whoami`.strip || "postgres"
  password = ENV["DB_PASSWORD"]? || ""

  Grant::Connections << Grant::Adapter::Pg.new(
    name: "pg",
    url: "postgres://#{username}:#{password}@#{host}:#{port}/#{database_name}"
  )
end