require "./spec_helper"

class PublicPagesSpec
  include RequestHelper
  include TestHelpers

  def handler
    Amber::Server.instance
  end
end

describe "Public Pages" do
  spec = PublicPagesSpec.new

  describe "GET /" do
    it "renders the homepage without authentication" do
      response = spec.get("/")
      response.status_code.should eq(200)
    end

    it "is accessible to unauthenticated users" do
      response = spec.get("/")
      response.status_code.should_not eq(302) # Should not redirect to login
    end
  end

  describe "GET /login" do
    it "renders the login page" do
      response = spec.get("/login")
      response.status_code.should eq(200)
    end

    it "is accessible without authentication" do
      response = spec.get("/login")
      response.status_code.should eq(200)
      response.body.should contain("login") # Should contain login form
    end
  end

  describe "Public routes accessibility" do
    it "allows access to marketing pages without authentication" do
      public_routes = ["/", "/login"]

      public_routes.each do |route|
        response = spec.get(route)
        response.status_code.should_not eq(302), "Route #{route} should not redirect"
        response.status_code.should eq(200), "Route #{route} should be accessible"
      end
    end
  end
end
