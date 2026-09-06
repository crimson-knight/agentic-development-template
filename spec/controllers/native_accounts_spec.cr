require "./spec_helper"

module NativeAccountSpec
  extend self
  JSON_HEADERS = HTTP::Headers{"Content-Type" => "application/json"}

  def login(email = "native@example.test", password = "password123")
    App.post("/api/native/v1/session", {email: email, password: password}.to_json, JSON_HEADERS)
  end

  def bearer(token : String)
    HTTP::Headers{"Authorization" => "Bearer #{token}", "Content-Type" => "application/json"}
  end

  def row_count : Int64
    App::Server::NativeSessions.writer.open { |db| db.query_one("SELECT count(*) FROM native_account_sessions", as: Int64) }
  end
end

describe "Native account API" do
  it "issues a bounded opaque session and stores only a digest" do
    user = TestData.create_regular_user("native@example.test")
    before = Time.utc.to_unix
    response = NativeAccountSpec.login
    response.status_code.should eq 201
    response.headers["Cache-Control"].should eq "no-store"
    response.headers["X-Content-Type-Options"].should eq "nosniff"
    response.headers.has_key?("Set-Cookie").should be_false
    response.headers.has_key?("Access-Control-Allow-Origin").should be_false
    payload = JSON.parse(response.body)
    token = payload["token"].as_s
    App::Server::NativeSessions.token?(token).should be_true
    payload["expires_at"].as_i64.should be >= before + 8.hours.total_seconds.to_i64
    payload["account"]["id"].as_i64.should eq user.id
    payload["account"]["account_type"].as_s.should eq "regular"
    response.body.should_not contain "password"
    stored = App::Server::NativeSessions.writer.open do |db|
      db.query_one("SELECT token_digest FROM native_account_sessions", as: String)
    end
    stored.should eq Digest::SHA256.hexdigest(token)
    stored.should_not eq token
    account = App.get("/api/native/v1/account", NativeAccountSpec.bearer(token))
    account.status_code.should eq 200
    JSON.parse(account.body)["account"]["email"].as_s.should eq user.email
  end

  it "authenticates existing admin accounts without confusing same-ID regular accounts" do
    regular = TestData.create_regular_user("regular@example.test")
    admin = TestData.create_admin_user("admin@example.test")
    regular.id.should eq admin.id
    response = NativeAccountSpec.login(admin.email, "adminpass123")
    response.status_code.should eq 201
    payload = JSON.parse(response.body)
    payload["account"]["account_type"].as_s.should eq "admin"
    headers = NativeAccountSpec.bearer(payload["token"].as_s)
    updated = App.patch("/api/native/v1/account", {display_name: "Admin 雪"}.to_json, headers)
    updated.status_code.should eq 200
    Users::Admin.find(admin.id).not_nil!.display_name.should eq "Admin 雪"
    Users::Regular.find(regular.id).not_nil!.display_name.should eq ""
  end

  it "returns the same fixed unauthorized result for missing users and wrong passwords" do
    TestData.create_regular_user("native@example.test")
    wrong = NativeAccountSpec.login(password: "wrong")
    missing = NativeAccountSpec.login("missing@example.test")
    wrong.status_code.should eq 401
    missing.status_code.should eq 401
    wrong.body.should eq missing.body
    wrong.body.should eq %({"error":"unauthorized"})
    NativeAccountSpec.row_count.should eq 0
  end

  it "never accepts an ambient browser cookie as native authentication" do
    TestData.create_regular_user("native@example.test")
    headers = TestData.session_headers("native@example.test", "password123")
    App.get("/settings", headers).status_code.should eq 200
    App.get("/api/native/v1/account", headers).status_code.should eq 401
    headers["Authorization"] = "Bearer bad"
    App.get("/api/native/v1/account", headers).status_code.should eq 401
  end

  it "uses the same name operation from web settings and native API" do
    user = TestData.create_regular_user("native@example.test")
    headers = NativeAccountSpec.bearer(JSON.parse(NativeAccountSpec.login.body)["token"].as_s)
    renamed = App.patch("/api/native/v1/account", {display_name: "  Android 雪 😀 é  "}.to_json, headers)
    renamed.status_code.should eq 200
    JSON.parse(renamed.body)["account"]["display_name"].as_s.should eq "Android 雪 😀 é"
    cookies = TestData.session_headers("native@example.test", "password123")
    App.get("/settings", cookies).body.should contain "Android 雪 😀 é"
    cookies["Content-Type"] = "application/x-www-form-urlencoded"
    App.post("/settings", URI::Params.encode({"display_name" => "<Web & native>"}), cookies).status_code.should eq 302
    Users::Regular.find(user.id).not_nil!.display_name.should eq "<Web & native>"
    App.get("/settings", cookies).body.should contain "&lt;Web &amp; native&gt;"
    JSON.parse(App.get("/api/native/v1/account", headers).body)["account"]["display_name"].as_s.should eq "<Web & native>"
    App.patch("/api/native/v1/account", {display_name: "a" * 65}.to_json, headers).status_code.should eq 422
    Users::Regular.find(user.id).not_nil!.display_name.should eq "<Web & native>"
    App.patch("/api/native/v1/account", {display_name: ""}.to_json, headers).status_code.should eq 200
    Users::Regular.find(user.id).not_nil!.display_name.should eq ""
  end

  it "only updates the authenticated account and rejects requested identity fields" do
    first = TestData.create_regular_user("native@example.test")
    second = TestData.create_regular_user("second@example.test")
    token = JSON.parse(NativeAccountSpec.login.body)["token"].as_s
    headers = NativeAccountSpec.bearer(token)
    App.patch("/api/native/v1/account", {display_name: "stolen", id: second.id}.to_json, headers).status_code.should eq 400
    App.patch("/api/native/v1/account", {display_name: "mine"}.to_json, headers).status_code.should eq 200
    Users::Regular.find(first.id).not_nil!.display_name.should eq "mine"
    Users::Regular.find(second.id).not_nil!.display_name.should eq ""
  end

  it "revokes only the signed-out session and returns a truly empty 204 response" do
    user = TestData.create_regular_user("native@example.test")
    first = App::Server::NativeSessions.issue(user)
    second = App::Server::NativeSessions.issue(user)
    response = App.delete("/api/native/v1/session", NativeAccountSpec.bearer(first.token))
    response.status_code.should eq 204
    response.body.should eq ""
    App.get("/api/native/v1/account", NativeAccountSpec.bearer(first.token)).status_code.should eq 401
    App.get("/api/native/v1/account", NativeAccountSpec.bearer(second.token)).status_code.should eq 200
    NativeAccountSpec.row_count.should eq 1
  end

  it "rejects duplicate authorization headers, malformed tokens and header prefixes" do
    user = TestData.create_regular_user("native@example.test")
    token = App::Server::NativeSessions.issue(user).token
    ["Basic #{token}", "Bearer #{token} ", "Bearer #{token}extra", "Bearer "].each do |value|
      App.get("/api/native/v1/account", HTTP::Headers{"Authorization" => value}).status_code.should eq 401
    end
    headers = NativeAccountSpec.bearer(token)
    headers.add("Authorization", "Bearer #{token}")
    App.get("/api/native/v1/account", headers).status_code.should eq 401
  end

  it "rejects ambiguous JSON, method overrides, wrong content types and oversized input" do
    invalid = ["{}", "[]", "null", "", "{", %({"email":"e","password":42}),
               %({"email":"e","password":"p","password":"q"}),
               %({"email":"e","password":"p","extra":"x"}),
               %({"email":"e","password":{}}), %({"email":"e","password":"p"}{}),
               String.new(Bytes[0xff])]
    invalid.each do |body|
      NativeApiIngress::LOGIN_THROTTLE.reset_for_spec
      App.post("/api/native/v1/session", body, NativeAccountSpec::JSON_HEADERS).status_code.should eq 400
    end
    NativeApiIngress::LOGIN_THROTTLE.reset_for_spec
    App.post("/api/native/v1/session", "a" * 4097, NativeAccountSpec::JSON_HEADERS).status_code.should eq 413
    App.post("/api/native/v1/session", "_method=DELETE", FORM_HEADERS).status_code.should eq 415
    App.post("/api/native/v1/session?_method=DELETE", "{}", NativeAccountSpec::JSON_HEADERS).status_code.should eq 400
    headers = NativeAccountSpec::JSON_HEADERS.dup
    headers["X-HTTP-Method-Override"] = "DELETE"
    App.post("/api/native/v1/session", "{}", headers).status_code.should eq 400
    App.get("/api/native/v1/account?token=secret").status_code.should eq 400
    App.get("/api/native/v1/unknown").status_code.should eq 404
    NativeAccountSpec.row_count.should eq 0
  end

  it "rate limits native login admission with bounded fixed errors" do
    10.times { App.post("/api/native/v1/session", "{}", NativeAccountSpec::JSON_HEADERS).status_code.should eq 400 }
    limited = App.post("/api/native/v1/session", "{}", NativeAccountSpec::JSON_HEADERS)
    limited.status_code.should eq 429
    limited.headers["Retry-After"].should eq "60"
    limited.body.should eq %({"error":"rate_limited"})
  end
end

describe "Native session expiry and invalidation" do
  it "enforces the idle timeout exactly at its boundary" do
    user = TestData.create_regular_user
    now = Time.utc
    issued = App::Server::NativeSessions.issue(user, now)
    App::Server::NativeSessions.authenticate(issued.token, now + 30.minutes).should be_nil
  end

  it "refreshes idle time without extending absolute lifetime" do
    user = TestData.create_regular_user
    now = Time.utc
    issued = App::Server::NativeSessions.issue(user, now)
    23.times do |step|
      App::Server::NativeSessions.authenticate(issued.token, now + 20.minutes * (step + 1)).should_not be_nil
    end
    App::Server::NativeSessions.authenticate(issued.token, now + 8.hours).should be_nil
  end

  it "invalidates sessions after a password change or account deletion" do
    user = TestData.create_regular_user
    issued = App::Server::NativeSessions.issue(user)
    user.password = "changed-password"
    user.save.should be_true
    App::Server::NativeSessions.authenticate(issued.token).should be_nil
    again = App::Server::NativeSessions.issue(user)
    user.destroy
    App::Server::NativeSessions.authenticate(again.token).should be_nil
    NativeAccountSpec.row_count.should eq 0
  end
end

describe "Native login throttle" do
  it "expires fixed windows, separates peers and bounds the number of buckets" do
    throttle = App::Server::NativeLoginThrottle.new(limit: 2, window: 1.minute, capacity: 2)
    now = 10.seconds
    throttle.allow?("one", now).should be_true
    throttle.allow?("one", now).should be_true
    throttle.allow?("one", now + 59.seconds).should be_false
    throttle.allow?("two", now).should be_true
    throttle.allow?("three", now).should be_false
    throttle.allow?("one", now + 1.minute).should be_true
    throttle.allow?("three", now + 1.minute).should be_true
  end
end
