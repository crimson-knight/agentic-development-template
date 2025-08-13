Amber::Server.configure do
  pipeline :web, :auth do
    # Plug is the method to use connect a pipe (middleware)
    # A plug accepts an instance of HTTP::Handler
    # plug Amber::Pipe::ClientIp.new(["X-Forwarded-For"])
    plug Amber::Pipe::Logger.new
    plug Amber::Pipe::Session.new
    plug Amber::Pipe::Flash.new
    plug Amber::Pipe::CSRF.new

    # Add the CurrentUserPipe to handle authentication
  end

  pipeline :auth do
    plug CurrentUserPipe.new
    plug AuthenticateUser.new
  end

  pipeline :api do
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
  end

  routes :auth do
    # Routes only available to authenticated users
    get "/dashboard", Authenticated::DashboardController, :index
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

  routes :static do
    # Each route is defined as follow
    # verb resource : String, controller : Symbol, action : Symbol
    get "/*", Amber::Controller::Static, :index
  end
end
