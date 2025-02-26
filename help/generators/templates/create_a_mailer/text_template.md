# Plain Text Email Template

Use this template to create a plain text email template. Replace placeholder values as needed.

```ecr
# src/views/mailers/{{mailer_name}}_mailer.txt.ecr
Welcome to Our Application
==========================

This is an example email template in plain text format.

<% if defined?(message) && message %>
<%= message %>
<% end %>

If you have any questions, please feel free to contact our support team.

Best regards,
Your Application Team

© <%= Time.utc.year %> Your Company. All rights reserved.
``` 