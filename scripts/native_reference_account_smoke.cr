require "http/client"
require "openssl"
require "uri"
require "html"
require "../src/app/accounts/remote"

# Real transport proof against a separately started task-only TLS server. This
# uses the synthetic account created by native_reference_seed.cr, not sign-up
# (which may send mail). Never print session/cookie/password material.
module NativeReferenceSmoke
  extend self

  def check(value, message : String)
    abort("FAIL: #{message}") unless value
  end

  def csrf(body : String) : String
    body.match(/name="_csrf" value="([^"]+)"/).try(&.[1]) || abort("Missing real web CSRF field")
  end

  class Browser
    @cookies = {} of String => String

    def initialize(@http : HTTP::Client)
    end

    def request(method : String, path : String, fields : Hash(String, String)? = nil)
      headers = HTTP::Headers.new
      headers["Cookie"] = @cookies.map { |key, value| "#{key}=#{value}" }.join("; ") unless @cookies.empty?
      headers["Content-Type"] = "application/x-www-form-urlencoded" if fields
      response = @http.exec(method, path, headers, body: fields.try { |values| URI::Params.encode(values) })
      response.headers.get?("Set-Cookie").try &.each do |line|
        parts = line.split(';', 2).first.split('=', 2)
        @cookies[parts[0]] = parts[1] if parts.size == 2
      end
      response
    end
  end

  def rejection(origin : URI, tls, content_type, declared_size, expected)
    tcp = TCPSocket.new(origin.host.not_nil!, origin.port || 443)
    tcp.read_timeout = 5.seconds
    socket = OpenSSL::SSL::Socket::Client.new(tcp, context: tls, sync_close: true, hostname: origin.host.not_nil!)
    begin
      # Do not send the declared body: an ingress rejection must not wait for it
      # or try the normal form method-override parser first.
      socket << "POST /api/native/v1/session HTTP/1.1\r\nHost: localhost\r\nContent-Type: #{content_type}\r\nContent-Length: #{declared_size}\r\nConnection: close\r\n\r\n"
      socket.flush
      response = HTTP::Client::Response.from_io(socket)
      check(response.status_code == expected, "early transport-body rejection")
    ensure
      socket.close
    end
  end

  def chunked_rejection(origin : URI, tls)
    tcp = TCPSocket.new(origin.host.not_nil!, origin.port || 443)
    tcp.read_timeout = 5.seconds
    socket = OpenSSL::SSL::Socket::Client.new(tcp, context: tls, sync_close: true, hostname: origin.host.not_nil!)
    begin
      socket << "POST /api/native/v1/session HTTP/1.1\r\nHost: localhost\r\nContent-Type: application/json\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n"
      socket << "1001\r\n" << ("a" * 4097) << "\r\n0\r\n\r\n"
      socket.flush
      check(HTTP::Client::Response.from_io(socket).status_code == 413, "unknown-length body is bounded")
    ensure
      socket.close
    end
  end

  def run
    origin = URI.parse(ARGV[0]? || abort("Pass https://localhost:<port> and the task CA certificate path"))
    check(origin.scheme == "https" && origin.host == "localhost" && origin.port &&
          {"", "/"}.includes?(origin.path) && origin.user.nil? && origin.password.nil? && origin.query.nil? && origin.fragment.nil?,
      "only an explicit localhost HTTPS origin is allowed")
    ca = ARGV[1]? || abort("Pass the task CA certificate path")
    tls = OpenSSL::SSL::Context::Client.new
    tls.ca_certificates = ca
    native = HTTP::Client.new(origin, tls: tls)
    browser_http = HTTP::Client.new(origin, tls: tls)
    native.read_timeout = browser_http.read_timeout = 10.seconds
    native.connect_timeout = browser_http.connect_timeout = 5.seconds
    browser = Browser.new(browser_http)
    begin
      untrusted = HTTP::Client.new(origin)
      untrusted.connect_timeout = 5.seconds
      untrusted.read_timeout = 5.seconds
      rejected = false
      begin
        untrusted.get("/api/native/v1/account")
      rescue OpenSSL::SSL::Error
        rejected = true
      ensure
        untrusted.close
      end
      check(rejected, "untrusted TLS must fail verification")

      email = "native-emulator@example.test"
      password = "Android-reference-only-2026!"
      page = browser.request("GET", "/login")
      check(page.status_code == 200, "real login page")
      token = csrf(page.body)
      blocked = browser.request("POST", "/login", {"email" => email, "password" => password})
      check(blocked.status_code == 403, "normal web login must retain CSRF protection")
      login = browser.request("POST", "/login", {"email" => email, "password" => password, "_csrf" => token})
      check(login.status_code == 302 && login.headers["Location"]? == "/dashboard", "real browser login")

      headers = HTTP::Headers{"Content-Type" => "application/json"}
      signed_in = native.post("/api/native/v1/session", headers, {email: email, password: password}.to_json)
      check(signed_in.status_code == 201, "native login over trusted TLS")
      session = App::Accounts::Wire.session(signed_in.body.to_slice)
      if expected = ARGV[2]?
        check(session.account.display_name == expected, "API sees the previously saved Android UI name")
        settings_before = browser.request("GET", "/settings")
        check(settings_before.status_code == 200 && settings_before.body.includes?(HTML.escape(expected)),
          "real web settings sees the previously saved Android UI name")
        puts "PASS: the existing Android UI update is visible through real web settings and the API before smoke-test edits."
      end
      check(signed_in.headers["Cache-Control"]? == "no-store" && !signed_in.headers.has_key?("Set-Cookie"), "private non-cookie response")
      headers["Authorization"] = "Bearer #{session.token}"
      mobile_name = "Android 雪 😀 é"
      renamed = native.patch("/api/native/v1/account", headers, {display_name: "  #{mobile_name}  "}.to_json)
      check(renamed.status_code == 200 && App::Accounts::Wire.account(renamed.body.to_slice).display_name == mobile_name, "native shared name update")
      settings = browser.request("GET", "/settings")
      check(settings.status_code == 200 && settings.body.includes?(mobile_name), "browser sees native update")
      denied = browser.request("POST", "/settings", {"display_name" => "must not save"})
      check(denied.status_code == 403, "settings must enforce real CSRF")
      name = "Web & Android <shared>"
      saved = browser.request("POST", "/settings", {"display_name" => name, "_csrf" => csrf(settings.body)})
      check(saved.status_code == 302 && saved.headers["Location"]? == "/settings", "browser shared name update")
      current = native.get("/api/native/v1/account", headers)
      check(current.status_code == 200 && App::Accounts::Wire.account(current.body.to_slice).display_name == name, "native sees browser update")
      check(browser.request("GET", "/settings").body.includes?("Web &amp; Android &lt;shared&gt;"), "web name output is escaped")
      duplicates = headers.dup
      duplicates.add("Authorization", headers["Authorization"])
      check(native.get("/api/native/v1/account", duplicates).status_code == 401, "real repeated auth headers are rejected")
      rejection(origin, tls, "application/x-www-form-urlencoded", 100_000, 415)
      rejection(origin, tls, "application/json", 100_000, 413)
      chunked_rejection(origin, tls)
      signed_out = native.delete("/api/native/v1/session", headers)
      check(signed_out.status_code == 204 && signed_out.body.empty?, "real empty logout response")
      check(native.get("/api/native/v1/account", headers).status_code == 401, "revoked session cannot reopen account")
      puts "PASS: verified TLS trust, real web CSRF, native sign-in, shared Unicode edits in both directions, escaping, duplicate headers, pre-body rejection and logout."
    ensure
      native.close
      browser_http.close
    end
  end
end

NativeReferenceSmoke.run
