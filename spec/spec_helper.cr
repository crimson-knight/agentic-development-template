ENV["AMBER_ENV"] ||= "test"
ENV["APP_ENV"] = "test"

require "spec"
require "../config/application"
require "amber/testing"

# Drive the real Amber pipeline from specs (v2 official test harness).
module App
  extend Amber::Testing::RequestHelpers
  extend Amber::Testing::Assertions
end

# Form-encoded headers for POSTing form data.
FORM_HEADERS = HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"}

# Data + auth helpers for specs.
module TestData
  extend self

  def create_regular_user(email = "test@example.com", password = "password123") : Users::Regular
    user = Users::Regular.new
    user.email = email
    user.password = password
    user.save
    user
  end

  def create_admin_user(email = "admin@example.com", password = "adminpass123") : Users::Admin
    admin = Users::Admin.new
    admin.email = email
    admin.password = password
    admin.save
    admin
  end

  # Log in through the real pipeline and return headers carrying the session
  # cookie, so authenticated-route specs can make authorized requests.
  def session_headers(email : String, password : String) : HTTP::Headers
    response = App.post("/login", "email=#{email}&password=#{password}", FORM_HEADERS)
    headers = HTTP::Headers.new
    if cookie = response.headers["Set-Cookie"]?
      headers["Cookie"] = cookie.split(";").first
    end
    headers
  end
end

# Clean user tables between tests.
Spec.before_each do
  connection = Grant::Connections["pg"]
  if connection
    connection[:writer].open do |db|
      db.exec("TRUNCATE TABLE native_account_sessions, regular_users, admin_users RESTART IDENTITY CASCADE")
    end
  end
  NativeApiIngress::LOGIN_THROTTLE.reset_for_spec
end
