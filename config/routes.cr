Amber::Server.configure do
  handler.before_routing(NativeApiIngress.new)

  # The native ingress owns bounded input and fixed error handling. Do not add
  # ambient browser sessions, permissive CORS or header/body logging here.
  pipeline :native_accounts do
  end

  pipeline :web, :auth do
    # Plug is the method to use connect a pipe (middleware)
    # A plug accepts an instance of HTTP::Handler
    # plug Amber::Pipe::ClientIp.new(["X-Forwarded-For"])
    # Error must be first in v2 so downstream exceptions render correctly.
    plug Amber::Pipe::Error.new
    plug Amber::Pipe::Logger.new
    plug Amber::Pipe::Session.new
    plug Amber::Pipe::Flash.new
    # CSRF protects real form posts (which carry csrf_tag); skip under test
    # where synthetic requests have no token.
    plug Amber::Pipe::CSRF.new unless ENV["AMBER_ENV"]? == "test"

    # Add the CurrentUserPipe to handle authentication
  end

  pipeline :auth do
    plug CurrentUserPipe.new
    plug AuthenticateUser.new
  end

  pipeline :api do
    plug Amber::Pipe::Error.new
    plug Amber::Pipe::Logger.new
    plug Amber::Pipe::Session.new
    plug Amber::Pipe::CORS.new
  end

  # All static content will run these transformations
  pipeline :static do
    # plug Amber::Pipe::PoweredByAmber.new
    plug Amber::Pipe::Static.new("./public")
  end

  routes :web do
    get "/", Public::HomeController, :index
    get "/login", Public::SessionController, :new
    post "/login", Public::SessionController, :create
    get "/signup", Public::RegistrationController, :new
    post "/signup", Public::RegistrationController, :create
  end

  routes :auth do
    # Routes only available to authenticated users
    get "/dashboard", Authenticated::DashboardController, :index
    get "/settings", Authenticated::SettingsController, :index
    post "/settings", Authenticated::SettingsController, :update
    get "/logout", Authenticated::SessionController, :destroy
    
    # Authenticated MCP endpoints
    get "/mcp/tools", Authenticated::McpToolsController, :list
    post "/mcp/tools/:name/execute", Authenticated::McpToolsController, :execute
    get "/mcp/tools/history", Authenticated::McpToolsController, :history
    get "/mcp/tools/configurations", Authenticated::McpToolsController, :configurations
  end

  routes :api do
    # MCP endpoints
    get "/mcp/handshake", ApiControllers::McpController, :handshake
  end

  routes :native_accounts do
    post "/api/native/v1/session", ApiControllers::NativeAccountsController, :create_session
    delete "/api/native/v1/session", ApiControllers::NativeAccountsController, :destroy_session
    get "/api/native/v1/account", ApiControllers::NativeAccountsController, :account
    patch "/api/native/v1/account", ApiControllers::NativeAccountsController, :update_account
  end

  routes :static do
    # Each route is defined as follow
    # verb resource : String, controller : Symbol, action : Symbol
    get "/*", Amber::Controller::Static, :index
  end
end
