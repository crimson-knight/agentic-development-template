#!/bin/crystal

require "./config/database.cr"
require "./db/migrations/*"
require "./src/models/*"
require "sam"

# Here you can define your tasks
# desc "with description to be used by help command"
# task "test" do
#   puts "ping"
# end


desc "db:seed - Performs seeding of the database. This is blank until you complete it."
task "db:seed" do
  puts "db:seed ran, but you need to complete it."
end
