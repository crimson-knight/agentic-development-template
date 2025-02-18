# Navigation Template & Instructions

1. Using the template below, create the navigation in the `src/views/layouts/_nav_.ecr` file.
2. 

```crystal
# src/views/layouts/_nav_.ecr
# 
# Add the following to the navigation:
<%- active = context.request.path == "/{{pluralized_resource_name}}" ? "active" : "" %>
<% if logged_in? %>
  <li class="nav-item <%= active %>">
    <a class="nav-link" href="/{{pluralized_resource_name}}">{{pluralized_resource_name}}</a>
  </li>
<% end %>
```