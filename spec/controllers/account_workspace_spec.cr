require "./spec_helper"

private class WorkspaceClient
  include RequestHelper
  property cookie = ""
  property csrf = ""

  def handler
    Amber::Server.instance.handler
  end

  def visit(path)
    capture(get(path, HTTP::Headers{"Cookie" => cookie}))
  end

  def submit(path, values = {} of String => String, csrf : Bool = true, accept = "text/html")
    values = values.dup
    values["_csrf"] = self.csrf if csrf
    capture(post(path, HTTP::Headers{"Cookie" => cookie, "Accept" => accept}, HTTP::Params.encode(values)))
  end

  def sign_in(email = "owner@example.test", password = "password123")
    visit("/login")
    submit("/login", {"email" => email, "password" => password})
  end

  private def capture(response)
    self.cookie = response.headers["Set-Cookie"].split(';').first if response.headers.has_key?("Set-Cookie")
    if token_match = response.body.match(/name="_csrf" value="([^"]+)"/)
      self.csrf = token_match[1]
    end
    response
  end
end

private def fixture_user(email = "owner@example.test")
  User.create!({email: email, password: "password123", password_confirmation: "password123", api_key: "", api_secret: ""})
end

describe "OSS account workspace" do
  it "requires sign-in for profile, settings and workspace" do
    client = WorkspaceClient.new
    %w(/profile /settings /dashboard).each do |path|
      response = client.visit(path)
      response.status_code.should eq(302)
      response.headers["Location"].should eq("/login")
    end
  end

  it "shows real account facts without sample business metrics or dead actions" do
    fixture_user
    client = WorkspaceClient.new
    client.sign_in
    response = client.visit("/dashboard")
    response.status_code.should eq(200)
    response.headers["Cache-Control"].should contain("no-store")
    response.body.should contain("owner@example.test")
    ["1,247", "$24,780", "New Project", "Invite Team", "john.doe@example.com", "24.7%"].each do |fake|
      response.body.should_not contain(fake)
    end
    response.body.should contain(%(href="/settings"))
    response.body.should contain(%(id="account-menu"))
  end

  it "renders /profile with actual settings and no sensitive account secrets" do
    owner = fixture_user
    client = WorkspaceClient.new
    client.sign_in
    response = client.visit("/profile")
    response.status_code.should eq(200)
    response.body.should contain("Profile &amp; settings")
    response.body.should contain(%(action="/settings/profile"))
    response.body.should_not contain(owner.password_digest)
    response.body.should_not contain("Passkeys")
  end

  it "persists normalized profile names but ignores another ID, email, role and session version" do
    owner = fixture_user
    other = fixture_user("other@example.test")
    client = WorkspaceClient.new
    client.sign_in
    client.visit("/settings")
    response = client.submit("/settings/profile", {"display_name" => "  Seth\n  Tucker  ", "id" => other.id.to_s, "email" => "hijack@example.test", "type" => "Admin", "session_version" => "attacker"})
    response.status_code.should eq(302)
    saved = User.find!(owner.id)
    saved.display_name.should eq("Seth Tucker")
    saved.email.should eq("owner@example.test")
    saved.type.should eq("User")
    saved.session_version.should_not eq("attacker")
    User.find!(other.id).display_name.should eq("")
    client.visit("/profile").body.should contain(%(value="Seth Tucker"))
  end

  it "rejects overlong names and escapes stored HTML" do
    owner = fixture_user
    client = WorkspaceClient.new
    client.sign_in
    client.visit("/settings")
    result = client.submit("/settings/profile", {"display_name" => "a" * 101})
    result.status_code.should eq(422)
    result.body.should contain(%(role="alert"))
    User.find!(owner.id).display_name.should eq("")
    client.submit("/settings/profile", {"display_name" => "<script>alert(1)</script>"})
    result = client.visit("/settings")
    result.body.should contain("&lt;script&gt;")
    result.body.should_not contain("<script>alert(1)</script>")
  end

  it "rejects writes without valid CSRF" do
    owner = fixture_user
    client = WorkspaceClient.new
    client.sign_in
    client.visit("/settings")
    %w(/settings/profile /settings/password /settings/sessions /logout).each do |path|
      client.submit(path, {"display_name" => "Bad"}, csrf: false).status_code.should eq(403)
    end
    User.find!(owner.id).display_name.should eq("")
    client.visit("/dashboard").status_code.should eq(200)
  end

  it "rejects incorrect current, short, mismatched, reused and byte-truncated passwords without echoing secrets" do
    owner = fixture_user
    client = WorkspaceClient.new
    client.sign_in
    client.visit("/settings")
    [{"wrong-secret", "replacement123", "replacement123"}, {"password123", "short", "short"},
     {"password123", "replacement123", "different123"}, {"password123", "password123", "password123"},
     {"password123", "a" * 72, "a" * 72}, {"password123", "é" * 40, "é" * 40}, {"z" * 72, "replacement123", "replacement123"}].each do |current, replacement, confirmation|
      result = client.submit("/settings/password", {"current_password" => current, "password" => replacement, "password_confirmation" => confirmation})
      result.status_code.should eq(422)
      result.body.should_not contain(%(value="#{replacement}"))
      result.body.should_not contain("wrong-secret")
      User.find!(owner.id).authenticate("password123").should_not be_nil
    end
  end

  it "changes a maximum-length password, rotates sessions and preserves the submitting browser" do
    owner = fixture_user
    first, second = WorkspaceClient.new, WorkspaceClient.new
    first.sign_in
    second.sign_in
    first.visit("/settings")
    before = first.cookie
    password = "a" * 71
    result = first.submit("/settings/password", {"current_password" => "password123", "password" => password, "password_confirmation" => password})
    result.status_code.should eq(302)
    first.cookie.should_not eq(before)
    first.visit("/settings").status_code.should eq(200)
    second.visit("/settings").status_code.should eq(302)
    User.find!(owner.id).authenticate(password).should_not be_nil
    WorkspaceClient.new.sign_in("owner@example.test", "password123").headers["Location"].should eq("/login")
    WorkspaceClient.new.sign_in("owner@example.test", password).headers["Location"].should eq("/dashboard")
  end

  it "signs out other sessions only after current-password confirmation" do
    fixture_user
    first, second = WorkspaceClient.new, WorkspaceClient.new
    first.sign_in
    second.sign_in
    first.visit("/settings")
    first.submit("/settings/sessions", {"current_password" => "wrong"}).status_code.should eq(422)
    second.visit("/settings").status_code.should eq(200)
    first.submit("/settings/sessions", {"current_password" => "password123"}).status_code.should eq(302)
    first.visit("/settings").status_code.should eq(200)
    second.visit("/settings").status_code.should eq(302)
  end

  it "makes GET logout safe and POST logout remove the correct session key" do
    fixture_user
    client = WorkspaceClient.new
    client.sign_in
    client.visit("/logout").status_code.should eq(200)
    client.visit("/dashboard").status_code.should eq(200)
    client.submit("/logout").status_code.should eq(302)
    client.visit("/dashboard").status_code.should eq(302)
  end

  it "does not enumerate unknown accounts during sign-in" do
    response = WorkspaceClient.new.sign_in("missing@example.test")
    response.status_code.should eq(302)
    response.headers["Location"].should eq("/login")
  end

  it "preserves JSON sign-in response compatibility" do
    fixture_user
    client = WorkspaceClient.new
    client.visit("/login")
    response = client.submit("/login", {"email" => "owner@example.test", "password" => "password123"}, accept: "application/json")
    response.status_code.should eq(200)
    JSON.parse(response.body)["redirect_url"].as_s.should eq("/dashboard")
    client.visit("/settings").status_code.should eq(200)
  end

  it "returns generic JSON failure for an unknown account" do
    client = WorkspaceClient.new
    client.visit("/login")
    response = client.submit("/login", {"email" => "missing@example.test", "password" => "password123"}, accept: "application/json")
    response.status_code.should eq(200)
    JSON.parse(response.body)["redirect_url"].as_s.should eq("/login")
    client.visit("/settings").status_code.should eq(302)
  end
end
