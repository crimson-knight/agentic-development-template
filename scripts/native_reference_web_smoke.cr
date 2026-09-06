require "http/client"
require "uri"

# Read-only route proof for a separately booted, isolated reference server.
# This does not establish CSRF enforcement, mobile authentication, or RBAC.
base = URI.parse(ARGV.first? || abort("Pass the isolated localhost server URL"))
unless base.scheme == "http" && {"127.0.0.1", "localhost"}.includes?(base.host) &&
       base.user.nil? && base.password.nil? && base.query.nil? && base.fragment.nil? &&
       {"", "/"}.includes?(base.path)
  abort("Only an explicit localhost HTTP origin is accepted")
end

client = HTTP::Client.new(base)
client.connect_timeout = 3.seconds
client.read_timeout = 5.seconds
begin
  {"/", "/login", "/signup"}.each do |path|
    response = client.get(path)
    abort("Public route failed: #{path}") unless response.status_code == 200
    abort("Public route did not render HTML: #{path}") unless response.body.includes?("<html")
    if path == "/login"
      abort("Login form is missing its current CSRF field") unless response.body.includes?("name=\"_csrf\"")
      abort("Login form still renders the legacy CSRF field") if response.body.includes?("name=\"authenticity_token\"")
    end
  end
  {"/dashboard", "/settings"}.each do |path|
    response = client.get(path)
    abort("Unauthenticated route did not redirect: #{path}") unless response.status_code == 302
    abort("Unauthenticated route did not redirect to login: #{path}") unless response.headers["Location"]? == "/login"
  end
  puts "PASS: actual AgentC server renders three public pages and protects dashboard/settings with login redirects."
ensure
  client.close
end
