module App::Android
  API_ORIGIN     = {{ env("AGENTC_ANDROID_API_ORIGIN") || "https://account.example.invalid" }}
  API_CONFIGURED = API_ORIGIN != "https://account.example.invalid"
end
