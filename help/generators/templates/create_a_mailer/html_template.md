# HTML Email Template

Use this template to create an HTML email template. Replace placeholder values as needed.

```ecr
<!-- src/views/mailers/{{mailer_name}}_mailer.html.ecr -->
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <h1 style="color: #333; border-bottom: 1px solid #eee; padding-bottom: 10px;">Welcome to Our Application</h1>
  
  <div style="padding: 20px 0;">
    <p>This is an example email template in HTML format.</p>
    
    <!-- Example of using variables passed from the mailer -->
    <% if defined?(message) && message %>
      <p><%= message %></p>
    <% end %>
    
    <p>If you have any questions, please feel free to contact our support team.</p>
  </div>
  
  <footer style="margin-top: 20px; color: #666; border-top: 1px solid #eee; padding-top: 10px;">
    <p>Best regards,<br>Your Application Team</p>
    <p style="font-size: 12px; color: #999;">
      © <%= Time.utc.year %> Your Company. All rights reserved.
    </p>
  </footer>
</div>
``` 