require "./spec_helper"

describe "Registration (Sign Up)" do
  describe "GET /signup" do
    it "renders the signup form" do
      response = App.get("/signup")
      response.status_code.should eq(200)
      response.body.should contain("/signup")
      response.body.should contain("password_confirmation")
    end
  end

  describe "POST /signup" do
    it "creates an account and redirects to the dashboard" do
      response = App.post("/signup",
        "email=new@test.com&password=password123&password_confirmation=password123", FORM_HEADERS)
      response.status_code.should eq(302)
      response.redirect_url.should eq("/dashboard")
      Users::Regular.find_by(email: "new@test.com").should_not be_nil
    end

    it "logs the new user in (sets a session cookie)" do
      response = App.post("/signup",
        "email=session@test.com&password=password123&password_confirmation=password123", FORM_HEADERS)
      response.headers["Set-Cookie"]?.should_not be_nil
    end

    it "rejects mismatched passwords" do
      response = App.post("/signup",
        "email=x@test.com&password=password123&password_confirmation=different", FORM_HEADERS)
      response.status_code.should eq(200)
      response.body.downcase.should contain("match")
      Users::Regular.find_by(email: "x@test.com").should be_nil
    end

    it "rejects a short password" do
      response = App.post("/signup",
        "email=y@test.com&password=short&password_confirmation=short", FORM_HEADERS)
      response.status_code.should eq(200)
      response.body.downcase.should contain("8 characters")
    end

    it "rejects an invalid email" do
      response = App.post("/signup",
        "email=notanemail&password=password123&password_confirmation=password123", FORM_HEADERS)
      response.status_code.should eq(200)
      response.body.downcase.should contain("valid email")
    end

    it "rejects a duplicate email" do
      TestData.create_regular_user("dupe@test.com", "password123")
      response = App.post("/signup",
        "email=dupe@test.com&password=password123&password_confirmation=password123", FORM_HEADERS)
      response.status_code.should eq(200)
      response.body.downcase.should contain("could not create")
    end
  end
end
