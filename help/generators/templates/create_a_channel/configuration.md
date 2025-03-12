# WebSocket Channel Configuration Template

Use this template to configure WebSocket channel in your application. Replace placeholder values as needed.

```crystal
# config/initializers/socket.cr
Amber::WebSockets.configure do |socket|
  # Add this channel to your WebSocket configuration
  socket.add_channel "{{channel_name}}", {{channel_name}}Channel
  
  # Optional: Configure channel-specific settings
  
  # Example: Configure topic pattern matching for this channel
  # Default is "{channel}:*" which allows subscribing to any topic in this channel
  # socket.add_channel "{{channel_name}}", {{channel_name}}Channel, "{{channel_name}}:{{custom_pattern}}"
  
  # Example: Add multiple topic patterns for a single channel
  # socket.add_channel "{{channel_name}}", {{channel_name}}Channel, "{{channel_name}}:public"
  # socket.add_channel "{{channel_name}}", {{channel_name}}Channel, "{{channel_name}}:private:*"
  
  # Note: Be sure to add any socket configuration if you haven't already
  # socket.add_socket "{{related_socket}}", {{related_socket}}Socket
end
``` 