require "jennifer"
require "jennifer/adapter/postgres"

{% if @top_level.has_constant? "Spec" %}
  APP_ENV = "test"
{% else %}
  APP_ENV = ENV["APP_ENV"]? || "development"
{% end %}

Jennifer::Config.configure do |conf|
  conf.read("config/database.yml", APP_ENV)
  conf.from_uri(ENV["DATABASE_URI"]) if ENV.has_key?("DATABASE_URI")
  conf.pool_size = (ENV["DB_CONNECTION_POOL"] ||= "5").to_i
  conf.logger.level = APP_ENV == "development" ? Log::Severity::Debug : Log::Severity::Error
end
