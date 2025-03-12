# WebSocket Configuration Template

Use this template to configure WebSocket connections in your application. Replace placeholder values as needed.

```crystal
# config/initializers/socket.cr
Amber::WebSockets.configure do |socket|
  # Register the socket handler
  socket.add_socket "{{socket_name}}", {{socket_name}}Socket

  # Optional: Set ping interval in seconds (default is 30)
  # socket.ping_interval = 10

  # Optional: Configure origin check - restrict which domains can connect to your WebSocket
  # socket.allowed_origins = ["example.com", "localhost"]
  
  # Optional: Set SSL settings for secure WebSockets (wss://)
  # socket.ssl = true
  # socket.ssl_key_file = "/path/to/key.pem"
  # socket.ssl_cert_file = "/path/to/cert.pem"
  
  # Optional: Configure idle timeout in seconds
  # socket.idle_timeout = 120
end
``` 