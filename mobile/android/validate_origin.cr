require "../../src/app/accounts/remote"

# Public compile-time configuration, never a credential. There is deliberately
# no production endpoint default in this open-source reference app.
origin = ENV["AGENTC_ANDROID_API_ORIGIN"]? || "https://account.example.invalid"
begin
  App::Accounts::HTTPRemote.validate_origin(origin)
rescue ArgumentError | URI::Error
  abort("AGENTC_ANDROID_API_ORIGIN must be a bounded HTTPS origin without credentials, path, query or fragment")
end
puts "Validated public Android API origin (no credentials are included)."
