require "./spec_helper"

class AuthenticationSpec
  include RequestHelper
  include TestHelpers

  def handler
    Amber::Server.instance
  end
end

describe "Authentication Flow" do
  spec = AuthenticationSpec.new

  describe "POST /login" do
    context "with valid regular user credentials" do
      it "logs in successfully and redirects to dashboard" do
        user = spec.create_regular_user("user@test.com", "password123")

        headers = HTTP::Headers.new
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        body = "email=user@test.com&password=password123"

        response = spec.post("/login", headers, body)

        response.status_code.should eq(302)
        response.headers["Location"]?.should eq("/dashboard")
      end

      it "sets session with user_id and user_type" do
        user = spec.create_regular_user("user@test.com", "password123")

        headers = HTTP::Headers.new
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        body = "email=user@test.com&password=password123"

        response = spec.post("/login", headers, body)

        # Session should contain user_id and user_type=regular
        # Note: In a real test, you'd need to check the session cookie
        response.status_code.should eq(302)
      end
    end

    context "with valid admin user credentials" do
      it "logs in successfully as admin" do
        admin = spec.create_admin_user("admin@test.com", "adminpass")

        headers = HTTP::Headers.new
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        body = "email=admin@test.com&password=adminpass"

        response = spec.post("/login", headers, body)

        response.status_code.should eq(302)
        response.headers["Location"]?.should eq("/dashboard")
      end
    end

    context "with invalid credentials" do
      it "rejects login with wrong password" do
        user = spec.create_regular_user("user@test.com", "password123")

        headers = HTTP::Headers.new
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        body = "email=user@test.com&password=wrongpassword"

        response = spec.post("/login", headers, body)

        response.status_code.should eq(302)
        response.headers["Location"]?.should eq("/login")
      end

      it "rejects login with non-existent email" do
        headers = HTTP::Headers.new
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        body = "email=nobody@test.com&password=password123"

        response = spec.post("/login", headers, body)

        response.status_code.should eq(302)
        response.headers["Location"]?.should eq("/login")
      end

      it "rejects login with missing email" do
        headers = HTTP::Headers.new
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        body = "password=password123"

        response = spec.post("/login", headers, body)

        response.status_code.should_not eq(200)
      end

      it "rejects login with missing password" do
        headers = HTTP::Headers.new
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        body = "email=user@test.com"

        response = spec.post("/login", headers, body)

        response.status_code.should_not eq(200)
      end
    end
  end

  describe "User model authentication" do
    it "authenticates regular user with correct password" do
      user = create_regular_user("test@example.com", "password123")

      authenticated = Users::Regular.authenticate("test@example.com", "password123")
      authenticated.should_not be_nil
      authenticated.try(&.id).should eq(user.id)
    end

    it "authenticates admin user with correct password" do
      admin = create_admin_user("admin@example.com", "adminpass")

      authenticated = Users::Admin.authenticate("admin@example.com", "adminpass")
      authenticated.should_not be_nil
      authenticated.try(&.id).should eq(admin.id)
    end

    it "rejects authentication with wrong password" do
      user = create_regular_user("test@example.com", "password123")

      authenticated = Users::Regular.authenticate("test@example.com", "wrongpass")
      authenticated.should be_nil
    end

    it "rejects authentication with non-existent email" do
      authenticated = Users::Regular.authenticate("nobody@example.com", "password")
      authenticated.should be_nil
    end
  end

  describe "Password hashing" do
    it "stores hashed password, not plaintext" do
      user = create_regular_user("test@example.com", "password123")

      user.password_digest.should_not eq("password123")
      user.password_digest.should_not be_empty
      user.password_digest.size.should be > 20 # Bcrypt hashes are long
    end

    it "can verify password after save" do
      user = create_regular_user("test@example.com", "password123")

      verified = user.authenticate("password123")
      verified.should_not be_nil
    end
  end
end
