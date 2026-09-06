require "../src/app/accounts/remote"

# Compile/run the actual client methods without Amber's server, Grant, PG or
# Crystal OpenSSL. This is an object-boundary probe, not Android runtime proof.
module AccountBoundary
  class Operation < Amber::Native::Operation
    def cancel : Nil
    end
  end

  class HTTP < Amber::Native::HTTPClient
    @completion : Proc(Amber::Native::HTTPResponse | Amber::Native::ServiceError, Nil)?

    def request(request : Amber::Native::HTTPRequest, &completion : Amber::Native::HTTPResponse | Amber::Native::ServiceError ->) : Amber::Native::Operation
      raise "Request escaped HTTPS origin" unless request.url.starts_with?("https://account.example.test/api/native/v1/")
      @completion = completion
      Operation.new
    end

    def complete(status, body)
      callback = @completion.not_nil!
      @completion = nil
      callback.call(Amber::Native::HTTPResponse.new(status, {"content-type" => ["application/json"]}, body.to_slice))
    end
  end

  def self.run
    transport = HTTP.new
    remote = App::Accounts::HTTPRemote.new(transport, "https://account.example.test")
    account = App::Accounts::Profile.new(1_i64, "native@example.test", "regular", "Android 雪")
    token = "t" * 43
    checks = 0
    remote.login("native@example.test", "synthetic-only") { |result| checks += 1 if result.is_a?(App::Accounts::Session) }
    transport.complete(201, {token: token, expires_at: 123_i64, account: account}.to_json)
    remote.account(token) { |result| checks += 1 if result.is_a?(App::Accounts::Profile) }
    transport.complete(200, {account: account}.to_json)
    remote.rename(token, "Android 雪") { |result| checks += 1 if result.is_a?(App::Accounts::Profile) }
    transport.complete(200, {account: account}.to_json)
    remote.logout(token) { |result| checks += 1 if result.nil? }
    transport.complete(204, "")
    raise "Client boundary operations failed" unless checks == 4
    puts "PASS: native-safe account client exercises sign-in, read, shared name update and sign-out."
  end
end

AccountBoundary.run
