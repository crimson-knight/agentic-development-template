# WebSocket Channel Template

Use this template to create a new WebSocket channel. Replace placeholder values as needed.

```crystal
# src/channels/{{channel_name}}_channel.cr
class {{channel_name}}Channel < Amber::WebSockets::Channel
  def handle_joined(client_socket, msg)
    # Called when a client joins the channel
    # msg contains any data sent by the client when joining
    
    # Example: Broadcasting join message to all clients
    rebroadcast!(msg, "user:joined")
    
    # Example: Sending welcome message to the joining client
    # client_socket.send({
    #   event: "welcome",
    #   data: { message: "Welcome to the {{channel_name}} channel!" },
    #   timestamp: Time.utc.to_s
    # }.to_json)
  end

  def handle_message(client_socket, msg)
    # Called when a message is received from a client
    # msg contains the message data
    
    # Example: Broadcasting message to all clients
    rebroadcast!(msg)
    
    # Example: Processing different message types
    # if msg["type"]? == "command"
    #   process_command(client_socket, msg)
    # else
    #   rebroadcast!(msg)
    # end
  end

  def handle_leave(client_socket)
    # Called when a client leaves the channel
    # Perform any cleanup or notification
    
    # Example: Broadcasting leave message
    rebroadcast!({event: "user:left"}, "user:left")
    
    # Example: Cleaning up user-specific data
    # remove_user_from_active_list(client_socket.id)
  end

  private def rebroadcast!(msg, event = "message")
    broadcast!({
      event: event,
      data: msg,
      timestamp: Time.utc.to_s
    }.to_json)
  end
  
  # Example: Additional helper methods
  # private def process_command(client_socket, msg)
  #   # Process special command messages
  # end
  
  # private def remove_user_from_active_list(socket_id)
  #   # Clean up user data when they leave
  # end
end
``` 