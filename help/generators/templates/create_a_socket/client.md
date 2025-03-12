# WebSocket Client JavaScript Template

Use this template to create client-side JavaScript for connecting to your WebSocket. Replace placeholder values as needed.

```javascript
// Client-side WebSocket connection
document.addEventListener('DOMContentLoaded', () => {
  // Create WebSocket connection
  const socket = new WebSocket(`ws://${window.location.host}/{{socket_name}}`);
  
  // Connection opened
  socket.addEventListener('open', (event) => {
    console.log('Connected to {{socket_name}} WebSocket');
    
    // Optional: Send authentication information
    // socket.send(JSON.stringify({
    //   type: 'auth',
    //   token: getUserToken()
    // }));
  });
  
  // Listen for messages
  socket.addEventListener('message', (event) => {
    console.log('Message from server:', event.data);
    
    // Parse the message if it's JSON
    try {
      const data = JSON.parse(event.data);
      handleMessage(data);
    } catch (e) {
      console.error('Error parsing message:', e);
    }
  });
  
  // Connection closed
  socket.addEventListener('close', (event) => {
    console.log('Disconnected from {{socket_name}} WebSocket');
    
    // Optional: Implement reconnection logic
    // setTimeout(() => {
    //   console.log('Attempting to reconnect...');
    //   // Recreate the WebSocket connection
    // }, 3000);
  });
  
  // Connection error
  socket.addEventListener('error', (event) => {
    console.error('WebSocket error:', event);
  });
  
  // Example function to handle different message types
  function handleMessage(data) {
    switch(data.type) {
      case 'update':
        updateUI(data.content);
        break;
      case 'notification':
        showNotification(data.content);
        break;
      default:
        console.log('Unknown message type:', data.type);
    }
  }
  
  // Example function to send a message to the server
  function sendMessage(type, content) {
    if (socket.readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify({
        type: type,
        content: content
      }));
    } else {
      console.error('WebSocket is not connected');
    }
  }
  
  // Expose the sendMessage function globally if needed
  window.sendSocketMessage = sendMessage;
});
``` 