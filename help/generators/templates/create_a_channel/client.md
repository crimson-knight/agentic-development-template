# WebSocket Channel Client JavaScript Template

Use this template to create client-side JavaScript for interacting with your WebSocket channel. Replace placeholder values as needed.

```javascript
// Client-side channel subscription
document.addEventListener('DOMContentLoaded', () => {
  // Create WebSocket connection
  const socket = new WebSocket(`ws://${window.location.host}/{{socket_path}}`);
  
  // Track connection state
  let isConnected = false;
  
  // Connection opened
  socket.addEventListener('open', (event) => {
    console.log('Connected to WebSocket server');
    isConnected = true;
    
    // Join the channel
    joinChannel();
  });
  
  // Function to join the channel
  function joinChannel() {
    if (!isConnected) return;
    
    // Send join message to subscribe to the channel
    socket.send(JSON.stringify({
      event: "join",
      topic: "{{channel_name}}:*", // Use specific topic pattern if needed
      payload: { 
        user: getCurrentUser(),
        // Add any additional join parameters
      }
    }));
  }
  
  // Listen for messages
  socket.addEventListener('message', (event) => {
    console.log('Message received:', event.data);
    
    try {
      const message = JSON.parse(event.data);
      
      // Handle different event types
      switch(message.event) {
        case "user:joined":
          handleUserJoined(message.data);
          break;
        case "message":
          handleChannelMessage(message.data);
          break;
        case "user:left":
          handleUserLeft(message.data);
          break;
        default:
          console.log('Unknown event type:', message.event);
      }
    } catch (e) {
      console.error('Error parsing message:', e);
    }
  });
  
  // Connection closed
  socket.addEventListener('close', (event) => {
    console.log('Disconnected from WebSocket server');
    isConnected = false;
    
    // Optional: Implement reconnection logic
    setTimeout(() => {
      console.log('Attempting to reconnect...');
      // Recreate the WebSocket connection
    }, 3000);
  });
  
  // Connection error
  socket.addEventListener('error', (event) => {
    console.error('WebSocket error:', event);
  });
  
  // Example function to send a message to the channel
  function sendChannelMessage(content) {
    if (!isConnected) {
      console.error('Cannot send message: not connected');
      return;
    }
    
    socket.send(JSON.stringify({
      event: "message",
      topic: "{{channel_name}}:*", // Use specific topic if needed
      payload: { 
        content,
        user: getCurrentUser(),
        timestamp: new Date().toISOString()
      }
    }));
  }
  
  // Example handler functions
  function handleUserJoined(data) {
    console.log('User joined:', data);
    // Update UI to show new user
  }
  
  function handleChannelMessage(data) {
    console.log('Channel message:', data);
    // Display message in UI
  }
  
  function handleUserLeft(data) {
    console.log('User left:', data);
    // Update UI to remove user
  }
  
  // Utility function to get current user info
  function getCurrentUser() {
    // Get user info from your application
    return {
      id: 'user-123', // Replace with actual user ID
      name: 'Example User' // Replace with actual user name
    };
  }
  
  // Expose functions globally if needed
  window.sendChannelMessage = sendChannelMessage;
});
``` 