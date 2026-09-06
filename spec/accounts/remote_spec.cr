require "spec"
require "../../src/app/accounts/remote"

module AccountRemoteSpec
  TOKEN   = "t" * 43
  PROFILE = App::Accounts::Profile.new(1_i64, "native@example.test", "regular", "Android 雪")

  class Operation < Amber::Native::Operation
    getter cancelled = false

    def cancel : Nil
      @cancelled = true
    end
  end

  class HTTP < Amber::Native::HTTPClient
    getter requests = [] of Amber::Native::HTTPRequest
    getter operation = Operation.new
    @completions = [] of Proc(Amber::Native::HTTPResponse | Amber::Native::ServiceError, Nil)

    def request(request : Amber::Native::HTTPRequest, &completion : Amber::Native::HTTPResponse | Amber::Native::ServiceError ->) : Amber::Native::Operation
      @requests << request
      @completions << completion
      @operation
    end

    def complete(status = 200, body = {account: PROFILE}.to_json, headers = {"content-type" => ["application/json"]})
      @completions.shift.call(Amber::Native::HTTPResponse.new(status, headers, body.to_slice))
    end

    def fail(code : Amber::Native::ServiceError::Code)
      @completions.shift.call(Amber::Native::ServiceError.new(code, "private transport details"))
    end
  end
end

describe App::Accounts::HTTPRemote do
  it "accepts only explicit HTTPS origins without embedded credentials or extra URL parts" do
    http = AccountRemoteSpec::HTTP.new
    remote = App::Accounts::HTTPRemote.new(http, "https://localhost:38248/")
    remote.origin.should eq "https://localhost:38248"
    ["http://localhost:38248", "https://u:p@host", "https://host/path", "https://host?q=x", "https://host#f",
     "https://", "https://host:0", "https://host:65536", "https://ho st", "https://ho%73t"].each do |origin|
      expect_raises(ArgumentError) { App::Accounts::HTTPRemote.new(http, origin) }
    end
  end

  it "posts credentials only in the JSON body to the configured origin and returns a cancellable operation" do
    http = AccountRemoteSpec::HTTP.new
    remote = App::Accounts::HTTPRemote.new(http, "https://account.example.test")
    result : App::Accounts::Session | App::Accounts::Failure | Nil = nil
    operation = remote.login("native@example.test", "test password") { |value| result = value }
    result.should be_nil
    request = http.requests.last
    request.method.should eq "POST"
    request.url.should eq "https://account.example.test/api/native/v1/session"
    request.headers.has_key?("Authorization").should be_false
    request.headers.has_key?("Cookie").should be_false
    request.timeout_ms.should eq 15_000
    JSON.parse(String.new(request.body.not_nil!))["password"].as_s.should eq "test password"
    operation.cancel
    http.operation.cancelled.should be_true
    http.complete(201, {token: AccountRemoteSpec::TOKEN, expires_at: 123_i64, account: AccountRemoteSpec::PROFILE}.to_json)
    result.as(App::Accounts::Session).account.title.should eq "Android 雪"
  end

  it "loads and edits the same account with a header token and shared name validation" do
    http = AccountRemoteSpec::HTTP.new
    remote = App::Accounts::HTTPRemote.new(http, "https://account.example.test")
    result : App::Accounts::Profile | App::Accounts::Failure | Nil = nil
    remote.account(AccountRemoteSpec::TOKEN) { |value| result = value }
    http.requests.last.headers["Authorization"].should eq "Bearer #{AccountRemoteSpec::TOKEN}"
    http.requests.last.body.should be_nil
    http.complete
    result.as(App::Accounts::Profile).display_name.should eq "Android 雪"
    remote.rename(AccountRemoteSpec::TOKEN, "  Edited 雪  ") { |value| result = value }
    request = http.requests.last
    request.method.should eq "PATCH"
    JSON.parse(String.new(request.body.not_nil!))["display_name"].as_s.should eq "Edited 雪"
    http.complete(422, %({"error":"invalid_display_name"}))
    result.should eq App::Accounts::Failure::InvalidName
    expect_raises(ArgumentError) { remote.rename(AccountRemoteSpec::TOKEN, "a" * 65) { |_| } }
    expect_raises(ArgumentError) { remote.account("invalid") { |_| } }
    http.requests.size.should eq 2
  end

  it "bounds encoded credentials before transport, including JSON escape expansion" do
    http = AccountRemoteSpec::HTTP.new
    remote = App::Accounts::HTTPRemote.new(http, "https://account.example.test")
    expect_raises(ArgumentError) { remote.login("e", "p" * 1025) { |_| } }
    expect_raises(ArgumentError) { remote.login("e", "\u0000" * 1024) { |_| } }
    expect_raises(ArgumentError) { remote.login("", "p") { |_| } }
    http.requests.should be_empty
  end

  it "maps authentication, admission and network errors without exposing remote details" do
    http = AccountRemoteSpec::HTTP.new
    remote = App::Accounts::HTTPRemote.new(http, "https://account.example.test")
    result : App::Accounts::Profile | App::Accounts::Failure | Nil = nil
    {401 => App::Accounts::Failure::Unauthorized, 429 => App::Accounts::Failure::RateLimited,
     503 => App::Accounts::Failure::Unavailable, 302 => App::Accounts::Failure::InvalidResponse}.each do |status, expected|
      remote.account(AccountRemoteSpec::TOKEN) { |value| result = value }
      http.complete(status, "private server details")
      result.should eq expected
    end
    remote.account(AccountRemoteSpec::TOKEN) { |value| result = value }
    http.fail(Amber::Native::ServiceError::Code::Cancelled)
    result.should eq App::Accounts::Failure::Cancelled
    remote.account(AccountRemoteSpec::TOKEN) { |value| result = value }
    http.fail(Amber::Native::ServiceError::Code::Network)
    result.should eq App::Accounts::Failure::Unavailable
  end

  it "rejects ambiguous, oversized and malformed account responses" do
    http = AccountRemoteSpec::HTTP.new
    remote = App::Accounts::HTTPRemote.new(http, "https://account.example.test")
    result : App::Accounts::Profile | App::Accounts::Failure | Nil = nil
    profile = AccountRemoteSpec::PROFILE.to_json
    [%({"account":#{profile},"account":#{profile}}), %({"account":#{profile},"unexpected":1}),
     %({"account":#{profile}}{}), %({"account":{"id":1,"id":2,"email":"e","account_type":"admin","display_name":""}}),
     %({"account":{"id":1,"email":"e","account_type":"root","display_name":""}}), "null", "{}", "a" * 8193,
     String.new(Bytes[0xff])].each do |body|
      remote.account(AccountRemoteSpec::TOKEN) { |value| result = value }
      http.complete(200, body)
      result.should eq App::Accounts::Failure::InvalidResponse
    end
    [{} of String => Array(String), {"content-type" => ["text/html"]},
     {"Content-Type" => ["application/json"], "content-type" => ["application/json"]}].each do |headers|
      remote.account(AccountRemoteSpec::TOKEN) { |value| result = value }
      http.complete(200, {account: AccountRemoteSpec::PROFILE}.to_json, headers)
      result.should eq App::Accounts::Failure::InvalidResponse
    end
  end

  it "rejects bad session tokens and missing/duplicate/invalid expiry fields" do
    http = AccountRemoteSpec::HTTP.new
    remote = App::Accounts::HTTPRemote.new(http, "https://account.example.test")
    result : App::Accounts::Session | App::Accounts::Failure | Nil = nil
    [{token: "bad", expires_at: 123, account: AccountRemoteSpec::PROFILE}.to_json,
     {token: AccountRemoteSpec::TOKEN, expires_at: 0, account: AccountRemoteSpec::PROFILE}.to_json,
     %({"token":"#{AccountRemoteSpec::TOKEN}","expires_at":1,"expires_at":2,"account":#{AccountRemoteSpec::PROFILE.to_json}}),
     {token: AccountRemoteSpec::TOKEN, account: AccountRemoteSpec::PROFILE}.to_json].each do |body|
      remote.login("e", "p") { |value| result = value }
      http.complete(201, body)
      result.should eq App::Accounts::Failure::InvalidResponse
    end
  end

  it "requires an empty 204 logout result and does not swallow caller exceptions" do
    http = AccountRemoteSpec::HTTP.new
    remote = App::Accounts::HTTPRemote.new(http, "https://account.example.test")
    result : App::Accounts::Failure? = App::Accounts::Failure::Unavailable
    remote.logout(AccountRemoteSpec::TOKEN) { |value| result = value }
    http.requests.last.method.should eq "DELETE"
    http.complete(204, "")
    result.should be_nil
    remote.logout(AccountRemoteSpec::TOKEN) { |value| result = value }
    http.complete(204, "unexpected")
    result.should eq App::Accounts::Failure::InvalidResponse
    remote.account(AccountRemoteSpec::TOKEN) { |_| raise ArgumentError.new("caller failure") }
    expect_raises(ArgumentError, "caller failure") { http.complete }
  end
end
