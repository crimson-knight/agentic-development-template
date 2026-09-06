require "json"
require "../platform/server/native_login_throttle"

class HTTP::Server::Context
  property native_fields : Hash(String, String)?
end

# This is installed before routing, because normal method-override resolution
# may otherwise parse a form body before a route-specific input limit runs.
class NativeApiIngress < Amber::Pipe::Base
  MAX_BODY       = 4096
  LOGIN_THROTTLE = App::Server::NativeLoginThrottle.new

  class Rejected < Exception
    getter status : Int32
    getter code : String

    def initialize(@status, @code)
      super("Native API request rejected")
    end
  end

  def call(context : HTTP::Server::Context)
    return call_next(context) unless context.request.path.starts_with?("/api/native/")
    native_call(context)
  end

  private def native_call(context : HTTP::Server::Context)
    response = context.response
    response.content_type = "application/json"
    response.headers["Cache-Control"] = "no-store"
    response.headers["X-Content-Type-Options"] = "nosniff"
    {% unless @top_level.has_constant?("Spec") %}
      # Direct TLS is intentionally required. Arbitrary forwarded headers must
      # not turn a plaintext listener into a supposedly protected endpoint.
      reject(426, "https_required") unless Amber::Server.instance.ssl_enabled?
    {% end %}
    request = context.request
    reject(400, "invalid_request") if request.query || request.headers.has_key?("X-HTTP-Method-Override")
    method = request.transport_method
    path = request.path
    expected = case {method, path}
               when {"POST", "/api/native/v1/session"}                                      then ["email", "password"]
               when {"PATCH", "/api/native/v1/account"}                                     then ["display_name"]
               when {"GET", "/api/native/v1/account"}, {"DELETE", "/api/native/v1/session"} then [] of String
               else                                                                              reject(404, "not_found")
               end
    if method == "POST"
      peer = request.remote_address.as?(Socket::IPAddress).try(&.address) || "unknown"
      unless LOGIN_THROTTLE.allow?(peer)
        response.headers["Retry-After"] = "60"
        reject(429, "rate_limited")
      end
    end
    if expected.empty?
      reject(400, "invalid_request") if (request.headers["Content-Length"]?.try(&.to_i64?) || 0) > 0 || request.headers.has_key?("Transfer-Encoding")
      context.native_fields = {} of String => String
    else
      type = request.headers["Content-Type"]?.try(&.split(';', 2).first.strip.downcase)
      reject(415, "json_required") unless type == "application/json"
      if length = request.headers["Content-Length"]?
        size = length.to_i64?
        reject(413, "request_too_large") unless size && 0 <= size <= MAX_BODY
      end
      input = request.body || reject(400, "invalid_request")
      bytes = Bytes.new(MAX_BODY + 1)
      size = 0
      while size < bytes.size
        count = input.read(bytes[size, bytes.size - size])
        break if count == 0
        size += count
      end
      reject(413, "request_too_large") if size > MAX_BODY
      body = String.new(bytes[0, size])
      reject(400, "invalid_request") unless body.valid_encoding?
      fields = {} of String => String
      parser = JSON::PullParser.new(body)
      parser.max_nesting = 2
      parser.read_object do |key|
        reject(400, "invalid_request") unless expected.includes?(key) && !fields.has_key?(key)
        fields[key] = parser.read_string
      end
      reject(400, "invalid_request") unless parser.kind.eof? && fields.size == expected.size
      context.native_fields = fields
      # The controller consumes the checked fields, not the generic params or
      # _json cache. The entire transport body has already been consumed.
      request.body = nil
    end
    call_next(context)
  rescue error : Rejected
    fail_response(context, error.status, error.code)
  rescue JSON::ParseException | IO::EOFError | ArgumentError
    fail_response(context, 400, "invalid_request")
  rescue
    # Never print exceptions/headers/body/token values on this private API path.
    Log.error { "Native account API request failed" }
    fail_response(context, 503, "unavailable")
  ensure
    context.native_fields = nil
  end

  private def reject(status : Int32, code : String) : NoReturn
    raise Rejected.new(status, code)
  end

  private def fail_response(context, status, code)
    context.response.status_code = status
    context.response.headers["Connection"] = "close"
    context.response.print({error: code}.to_json)
  end
end
