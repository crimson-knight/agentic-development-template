# Create A Channel

## Prerequisites

Required:
- The name of the channel
- The purpose of the channel (chat, notifications, etc.)

Optional:
- Message types and formats
- Authorization requirements
- Client handling requirements

Review the information that you have been provided to ensure it includes all of the required information.
If there is any missing information or vague information, prompt the user for the missing information before proceeding.

## Steps

1. Create the channel file in `src/channels` directory using the following template:

```crystal
# src/channels/{{channel_name}}_channel.cr
class {{channel_name}}Channel < Amber::WebSockets::Channel
  def handle_joined(client_socket, msg)
    # Called when a client joins the channel
    # msg contains any data sent by the client when joining
    
    # Example: Broadcasting join message to all clients
    rebroadcast!(msg, "user:joined")
  end

  def handle_message(client_socket, msg)
    # Called when a message is received from a client
    # msg contains the message data
    
    # Example: Broadcasting message to all clients
    rebroadcast!(msg)
  end

  def handle_leave(client_socket)
    # Called when a client leaves the channel
    # Perform any cleanup or notification
    
    # Example: Broadcasting leave message
    rebroadcast!({event: "user:left"})
  end

  private def rebroadcast!(msg, event = "message")
    broadcast!({
      event: event,
      data: msg,
      timestamp: Time.utc.to_s
    }.to_json)
  end
end
```

2. Update the channel configuration in `config/initializers/socket.cr`:

```crystal
Amber::WebSockets.configure do |socket|
  socket.add_channel "{{channel_name}}", {{channel_name}}Channel
end
```

3. Add the channel subscription to your JavaScript client:

```javascript
// Example client-side subscription
const socket = new WebSocket("ws://localhost:3000/{{channel_name}}")

socket.onopen = () => {
  // Join the channel
  socket.send(JSON.stringify({
    event: "join",
    topic: "{{channel_name}}:*",
    payload: { user: "example_user" }
  }))
}

socket.onmessage = (event) => {
  const message = JSON.parse(event.data)
  
  switch(message.event) {
    case "user:joined":
      console.log("User joined:", message.data)
      break
    case "message":
      console.log("New message:", message.data)
      break
    case "user:left":
      console.log("User left:", message.data)
      break
  }
}

// Example: Sending a message to the channel
function sendMessage(content) {
  socket.send(JSON.stringify({
    event: "message",
    topic: "{{channel_name}}:*",
    payload: { content }
  }))
}
```

## Common Customization Points

1. Message Handling
   - Add custom message types
   - Implement message filtering
   - Add message persistence

2. Authorization
   - Add channel join authorization
   - Implement user-specific channels
   - Add message permission checks

3. Broadcasting
   - Customize broadcast targets
   - Add message transformations
   - Implement private messages

4. State Management
   - Track channel members
   - Maintain channel state
   - Handle reconnections
``` 