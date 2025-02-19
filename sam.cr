#!/bin/crystal

require "./config/database.cr"
require "./db/migrations/*"
require "./src/models/**"
require "sam"

load_dependencies "jennifer"

# Here you can define your tasks
# desc "with description to be used by help command"
# task "test" do
#   puts "ping"
# end

desc "db:seed - Performs seeding of the database."
namespace "db" do
  task "seed" do
    # Create a test user for authentication
    Admin.create({ :email => "admin@example.com", :password => "AdminPassword", :password_confirmation => "AdminPassword", :api_key => "test-api-key", :api_secret => "test-api-secret" })
    User.create({ :email => "user@example.com", :password => "UserPassword", :password_confirmation => "UserPassword", :api_key => "test-api-key", :api_secret => "test-api-secret" })
    Api.create({ :email => "api@example.com", :password => "ApiPassword", :password_confirmation => "ApiPassword", :api_key => "test-api-key", :api_secret => "test-api-secret" })

    # Add any additional seed data here
  end
end

desc "Drops the database, creates it, runs migrations, and seeds the database."
namespace "db" do
  task "reset", ["db:drop", "db:create", "db:migrate", "db:seed"] do
    puts "The database has been reset."
  end
end
