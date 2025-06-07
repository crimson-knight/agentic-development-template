require "jennifer"
require "jennifer/adapter/postgres"

{% if @top_level.has_constant? "Spec" %}
  APP_ENV = "test"
{% else %}
  APP_ENV = ENV["APP_ENV"]? || "development"
{% end %}

Jennifer::Config.configure do |conf|
  conf.read("config/database.yml", APP_ENV)
  # Support both DATABASE_URL (DigitalOcean) and DATABASE_URI
  database_url = ENV["DATABASE_URL"]? || ENV["DATABASE_URI"]?

  # Jennifer only supports `postgres://` not `postgresql://`
  if database_url.starts_with?("postgresql://")
    database_url = database_url.gsub("postgresql://", "postgres://")
  end

  conf.from_uri(database_url) if database_url
  conf.pool_size = (ENV["DB_CONNECTION_POOL"] ||= "5").to_i
  conf.logger.level = APP_ENV == "development" ? Log::Severity::Debug : Log::Severity::Error
end
