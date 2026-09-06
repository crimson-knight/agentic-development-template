require "./spec_helper"

describe "Authentication Flow" do
  describe "POST /login" do
    context "with valid regular user credentials" do
      it "logs in and redirects to the dashboard" do
        TestData.create_regular_user("user@test.com", "password123")
        response = App.post("/login", "email=user@test.com&password=password123", FORM_HEADERS)
        response.status_code.should eq(302)
        response.redirect_url.should eq("/dashboard")
      end
    end

    context "with valid admin credentials" do
      it "logs in and redirects to the dashboard" do
        TestData.create_admin_user("admin@test.com", "adminpass123")
        response = App.post("/login", "email=admin@test.com&password=adminpass123", FORM_HEADERS)
        response.status_code.should eq(302)
        response.redirect_url.should eq("/dashboard")
      end
    end

    context "with invalid credentials" do
      it "rejects a wrong password" do
        TestData.create_regular_user("user@test.com", "password123")
        response = App.post("/login", "email=user@test.com&password=wrong", FORM_HEADERS)
        response.status_code.should eq(302)
        response.redirect_url.should eq("/login")
      end

      it "rejects a non-existent email" do
        response = App.post("/login", "email=nobody@test.com&password=password123", FORM_HEADERS)
        response.status_code.should eq(302)
        response.redirect_url.should eq("/login")
      end

      it "does not log in with a missing password" do
        TestData.create_regular_user("user@test.com", "password123")
        response = App.post("/login", "email=user@test.com", FORM_HEADERS)
        response.status_code.should_not eq(200)
      end
    end
  end

  describe "User model authentication" do
    it "authenticates a regular user with the correct password" do
      user = TestData.create_regular_user("test@example.com", "password123")
      Users::Regular.authenticate("test@example.com", "password123").try(&.id).should eq(user.id)
    end

    it "authenticates an admin user with the correct password" do
      admin = TestData.create_admin_user("admin@example.com", "adminpass123")
      Users::Admin.authenticate("admin@example.com", "adminpass123").try(&.id).should eq(admin.id)
    end

    it "rejects a wrong password" do
      TestData.create_regular_user("test@example.com", "password123")
      Users::Regular.authenticate("test@example.com", "nope").should be_nil
    end

    it "rejects a non-existent email" do
      Users::Regular.authenticate("nobody@example.com", "password").should be_nil
    end
  end

  describe "Password hashing" do
    it "stores a bcrypt hash, not plaintext" do
      user = TestData.create_regular_user("test@example.com", "password123")
      user.password_digest.should_not eq("password123")
      user.password_digest.size.should be > 20
    end

    it "verifies the password after save" do
      user = TestData.create_regular_user("test@example.com", "password123")
      user.authenticate("password123").should_not be_nil
    end
  end
end
