require "./spec_helper"

describe "Authenticated Routes" do
  describe "GET /dashboard" do
    it "redirects to login when unauthenticated" do
      response = App.get("/dashboard")
      response.status_code.should eq(302)
      response.redirect_url.should eq("/login")
    end

    it "allows access for an authenticated regular user" do
      TestData.create_regular_user("reg@test.com", "password123")
      headers = TestData.session_headers("reg@test.com", "password123")
      App.get("/dashboard", headers).status_code.should eq(200)
    end

    it "allows access for an authenticated admin" do
      TestData.create_admin_user("adm@test.com", "adminpass123")
      headers = TestData.session_headers("adm@test.com", "adminpass123")
      App.get("/dashboard", headers).status_code.should eq(200)
    end
  end

  describe "GET /settings" do
    it "redirects to login when unauthenticated" do
      response = App.get("/settings")
      response.status_code.should eq(302)
      response.redirect_url.should eq("/login")
    end

    it "shows the current user's email when authenticated" do
      TestData.create_regular_user("me@test.com", "password123")
      headers = TestData.session_headers("me@test.com", "password123")
      response = App.get("/settings", headers)
      response.status_code.should eq(200)
      response.body.should contain("me@test.com")
    end

    it "shows the account type" do
      TestData.create_admin_user("adm2@test.com", "adminpass123")
      headers = TestData.session_headers("adm2@test.com", "adminpass123")
      App.get("/settings", headers).body.should contain("Admin")
    end
  end

  describe "Authentication pipe" do
    it "leaves the request unauthenticated with no session" do
      App.get("/dashboard").status_code.should eq(302)
    end

    it "authenticates the request with a valid session" do
      TestData.create_regular_user("pipe@test.com", "password123")
      headers = TestData.session_headers("pipe@test.com", "password123")
      App.get("/dashboard", headers).status_code.should eq(200)
    end
  end
end
