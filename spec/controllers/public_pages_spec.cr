require "./spec_helper"

describe "Public Pages" do
  it "renders the homepage without authentication" do
    App.get("/").status_code.should eq(200)
  end

  it "renders the login page" do
    response = App.get("/login")
    response.status_code.should eq(200)
    response.body.downcase.should contain("sign in")
  end

  it "renders the signup page" do
    response = App.get("/signup")
    response.status_code.should eq(200)
    response.body.downcase.should contain("create")
  end

  it "does not redirect public routes to login" do
    ["/", "/login", "/signup"].each do |route|
      App.get(route).status_code.should eq(200)
    end
  end
end
