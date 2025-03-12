# WebSocket Template

Use this template to create a new WebSocket connection handler. Replace placeholder values as needed.

```crystal
# src/sockets/{{socket_name}}_socket.cr
struct {{socket_name}}Socket < Amber::WebSockets::ClientSocket
  # Called when a client connects to the socket
  # Return true to accept the connection, false to reject it
  def on_connect
    # Implement authentication logic here if needed
    # Example with JWT token:
    # token = params["token"]?
    # return false unless token && valid_token?(token)
    
    true
  end

  # Optional: Handle disconnection - called when a client disconnects
  def on_disconnect
    # Clean up any resources or handle disconnection logic
    # Example: 
    # notify_user_offline(user_id)
  end

  # Optional: Handle binary messages
  def on_binary(bytes : Bytes)
    # Handle binary data received from the client
    # Example:
    # process_binary_data(bytes)
  end

  # Optional: Handle ping messages
  def on_ping(message : String)
    # Handle ping messages from the client
    # The framework automatically responds with a pong
  end

  # Optional: Handle pong messages
  def on_pong(message : String)
    # Handle pong messages from the client
    # Typically used to measure latency
  end
end
``` 