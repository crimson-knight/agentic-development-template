require "amber/native"
require "uri"
require "set"
require "./profile"

module App::Accounts
  enum Failure
    Unauthorized
    InvalidName
    RateLimited
    Unavailable
    InvalidResponse
    Cancelled
  end

  record Session, token : String, expires_at : Int64, account : Profile

  # Strict bounded wire data, shared by the native client and its host tests.
  # JSON::Serializable alone accepts duplicate keys; this protocol does not.
  module Wire
    MAX_RESPONSE = 8192

    def self.token?(value : String) : Bool
      value.matches?(/\A[A-Za-z0-9_-]{43}\z/)
    end

    def self.parser(body : Bytes) : JSON::PullParser
      raise ArgumentError.new("Invalid account response") if body.size > MAX_RESPONSE
      text = String.new(body)
      raise ArgumentError.new("Invalid account response") unless text.valid_encoding?
      JSON::PullParser.new(text).tap { |parser| parser.max_nesting = 3 }
    end

    def self.fields(parser : JSON::PullParser, expected : Array(String), &block : String ->) : Nil
      seen = Set(String).new
      parser.read_object do |key|
        raise ArgumentError.new("Invalid account response") unless expected.includes?(key) && seen.add?(key)
        yield key
      end
      raise ArgumentError.new("Invalid account response") unless seen.size == expected.size
    end

    def self.profile(parser : JSON::PullParser) : Profile
      id = 0_i64
      email = type = name = ""
      fields(parser, ["id", "email", "account_type", "display_name"]) do |key|
        case key
        when "id"           then id = parser.read_int
        when "email"        then email = parser.read_string
        when "account_type" then type = parser.read_string
        when "display_name" then name = parser.read_string
        end
      end
      account = Profile.new(id, email, type, name)
      raise ArgumentError.new("Invalid account response") unless account.valid?
      account
    end

    def self.account(body : Bytes) : Profile
      parser = parser(body)
      account : Profile? = nil
      fields(parser, ["account"]) { |_| account = profile(parser) }
      raise ArgumentError.new("Invalid account response") unless parser.kind.eof?
      account.not_nil!
    end

    def self.session(body : Bytes) : Session
      parser = parser(body)
      token = ""
      expires = 0_i64
      account : Profile? = nil
      fields(parser, ["token", "expires_at", "account"]) do |key|
        case key
        when "token"      then token = parser.read_string
        when "expires_at" then expires = parser.read_int
        when "account"    then account = profile(parser)
        end
      end
      raise ArgumentError.new("Invalid account response") unless parser.kind.eof? && token?(token) && expires > 0
      Session.new(token, expires, account.not_nil!)
    end
  end

  abstract class Remote
    abstract def origin : String
    abstract def login(email : String, password : String, &completion : Session | Failure ->) : Amber::Native::Operation
    abstract def account(token : String, &completion : Profile | Failure ->) : Amber::Native::Operation
    abstract def rename(token : String, name : String, &completion : Profile | Failure ->) : Amber::Native::Operation
    abstract def logout(token : String, &completion : Nil | Failure ->) : Amber::Native::Operation
  end

  # Platform HTTP owns TLS, timeout, cancellation and delivery on the application
  # thread. No Crystal HTTP/OpenSSL, database, browser cookie or redirect adapter.
  class HTTPRemote < Remote
    getter origin : String

    def initialize(@http : Amber::Native::HTTPClient, origin : String)
      @origin = self.class.validate_origin(origin)
    end

    def self.validate_origin(origin : String) : String
      uri = URI.parse(origin)
      unless origin.bytesize <= 1024 && uri.scheme == "https" && uri.host.try { |host| !host.empty? && host.ascii_only? && !host.includes?('%') } &&
             uri.user.nil? && uri.password.nil? && uri.query.nil? && uri.fragment.nil? &&
             {"", "/"}.includes?(uri.path) && (uri.port.nil? || 1 <= uri.port.not_nil! <= 65535) &&
             origin.ascii_only? && !origin.includes?('%') && !origin.each_char.any?(&.whitespace?)
        raise ArgumentError.new("Configure an HTTPS account API origin without credentials, path, query or fragment")
      end
      origin.ends_with?('/') ? origin.byte_slice(0, origin.bytesize - 1) : origin
    end

    def login(email : String, password : String, &completion : Session | Failure ->) : Amber::Native::Operation
      unless email.valid_encoding? && password.valid_encoding? && 1 <= email.bytesize <= 255 && 1 <= password.bytesize <= 1024
        raise ArgumentError.new("Enter an email and password within the supported size limits")
      end
      body = {email: email, password: password}.to_json.to_slice
      @http.request(request("POST", "/session", body: body)) do |result|
        completion.call(decode_session(result))
      end
    end

    def account(token : String, &completion : Profile | Failure ->) : Amber::Native::Operation
      @http.request(request("GET", "/account", token)) { |result| completion.call(decode_account(result)) }
    end

    def rename(token : String, name : String, &completion : Profile | Failure ->) : Amber::Native::Operation
      body = {display_name: DisplayName.normalize(name)}.to_json.to_slice
      @http.request(request("PATCH", "/account", token, body)) do |result|
        decoded = result.is_a?(Amber::Native::HTTPResponse) && result.status == 422 ? Failure::InvalidName : decode_account(result)
        completion.call(decoded)
      end
    end

    def logout(token : String, &completion : Nil | Failure ->) : Amber::Native::Operation
      @http.request(request("DELETE", "/session", token)) do |result|
        decoded = if result.is_a?(Amber::Native::HTTPResponse) && result.status == 204 && result.body.empty?
                    nil
                  else
                    failure(result) || Failure::InvalidResponse
                  end
        completion.call(decoded)
      end
    end

    private def request(method, path, token : String? = nil, body : Bytes? = nil)
      raise ArgumentError.new("Account request exceeds the 4 KiB input limit") if body && body.size > 4096
      headers = {"Accept" => "application/json"}
      headers["Content-Type"] = "application/json" if body
      if token
        raise ArgumentError.new("Invalid account session") unless Wire.token?(token)
        headers["Authorization"] = "Bearer #{token}"
      end
      Amber::Native::HTTPRequest.new(method, "#{@origin}/api/native/v1#{path}", headers, body, timeout_ms: 15_000)
    end

    private def failure(result) : Failure?
      case result
      when Amber::Native::ServiceError
        result.code.cancelled? ? Failure::Cancelled : Failure::Unavailable
      when Amber::Native::HTTPResponse
        case result.status
        when 401      then Failure::Unauthorized
        when 429      then Failure::RateLimited
        when 500..599 then Failure::Unavailable
        end
      end
    end

    private def json?(response : Amber::Native::HTTPResponse) : Bool
      values = response.headers.select { |key, _| key.downcase == "content-type" }.values.flatten
      values.size == 1 && values.first.split(';', 2).first.strip.downcase == "application/json"
    end

    private def decode_session(result) : Session | Failure
      if failed = failure(result)
        return failed
      end
      return Failure::InvalidResponse unless result.is_a?(Amber::Native::HTTPResponse) && result.status == 201 && json?(result)
      Wire.session(result.body)
    rescue JSON::ParseException | ArgumentError | OverflowError
      Failure::InvalidResponse
    end

    private def decode_account(result) : Profile | Failure
      if failed = failure(result)
        return failed
      end
      return Failure::InvalidResponse unless result.is_a?(Amber::Native::HTTPResponse) && result.status == 200 && json?(result)
      Wire.account(result.body)
    rescue JSON::ParseException | ArgumentError | OverflowError
      Failure::InvalidResponse
    end
  end
end
