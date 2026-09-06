require "./spec_helper"

describe "Permission-Based Access Control" do
  describe "User type identification" do
    it "identifies Users::Regular" do
      TestData.create_regular_user.should be_a(Users::Regular)
    end

    it "identifies Users::Admin" do
      TestData.create_admin_user.should be_a(Users::Admin)
    end

    it "uses the CurrentUser union type for both user kinds" do
      user : CurrentUser = TestData.create_regular_user
      admin : CurrentUser = TestData.create_admin_user("a2@test.com")
      user.should be_a(Users::Regular)
      admin.should be_a(Users::Admin)
    end
  end

  describe "Admin API credentials" do
    it "generates API credentials for new admins" do
      admin = TestData.create_admin_user
      admin.api_key.should_not be_nil
      admin.api_secret.should_not be_nil
      admin.api_key.not_nil!.size.should be > 20
      admin.api_secret.not_nil!.size.should be > 20
    end

    it "regular users have no api_key" do
      TestData.create_regular_user.responds_to?(:api_key).should be_false
    end

    it "authenticates an admin by API key" do
      admin = TestData.create_admin_user
      result = Users::Admin.authenticate_by_api_key(admin.api_key.not_nil!, admin.api_secret.not_nil!)
      result.try(&.id).should eq(admin.id)
    end

    it "rejects API authentication with the wrong secret" do
      admin = TestData.create_admin_user
      Users::Admin.authenticate_by_api_key(admin.api_key.not_nil!, "wrong-secret").should be_nil
    end
  end

  # Future work (premium template covers full RBAC): admin-only route
  # authorization and per-user settings visibility.
  pending "denies regular users access to admin-only MCP tools"
  pending "returns 403 Forbidden for admin-only actions by regular users"
  pending "restricts settings visibility to the owning user"
end
