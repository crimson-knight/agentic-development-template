# The pinned Amber pipeline turns raised CSRF exceptions into a misleading 404.
# Keep the same token validation and return a deliberate, non-mutating 403.
class AccountCSRFPipe < Amber::Pipe::CSRF
  def call(context : HTTP::Server::Context)
    if valid_http_method?(context) || Amber::Pipe::CSRF.token_strategy.valid_token?(context)
      call_next(context)
    else
      context.response.status_code = 403
      context.response.content_type = "text/html"
      context.response.headers["Cache-Control"] = "no-store"
      context.response.print "<!doctype html><html lang=\"en\"><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>Refresh this page</title><main><h1>Please refresh this page</h1><p>Your form could not be verified. Nothing was changed.</p><a href=\"/settings\">Return to account settings</a></main></html>"
    end
  end
end
