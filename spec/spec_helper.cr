ENV["AMBER_ENV"] ||= "test"
ENV["APP_ENV"] = "test"

require "spec"
require "../config/application"

# Helper to create test users
module TestHelpers
  def create_regular_user(email = "test@example.com", password = "password123")
    user = Users::Regular.new
    user.email = email
    user.password = password
    user.save
    user
  end

  def create_admin_user(email = "admin@example.com", password = "adminpass123")
    admin = Users::Admin.new
    admin.email = email
    admin.password = password
    admin.save
    admin
  end

  def login_as(user : Users::Regular | Users::Admin)
    user_type = user.is_a?(Users::Admin) ? "admin" : "regular"
    session = {} of String => Int64 | String
    session["user_id"] = user.id.not_nil!
    session["user_type"] = user_type
    session
  end
end

# Database cleanup before each test
Spec.before_each do
  # Clean up users between tests
  Grant::Connections["pg"].exec("TRUNCATE TABLE regular_users, admin_users RESTART IDENTITY CASCADE")
end
