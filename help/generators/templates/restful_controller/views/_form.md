# Form View Template & Instructions

1. Using the notes file, remind yourself of the attributes of the resource.

2. Using the template below, create the form view in the `src/views/{namespace}/#{controller_name}` directory with the file name `_form.ecr`.

```crystal
# src/views/{namespace}/#{controller_name}/_form.ecr
<%- if {{singular_resource_name}}.errors %>
  <ul class="errors">
  <%- {{singular_resource_name}}.errors.each do |error| %>
    <li><%= error.to_s %></li>
  <%- end %>
  </ul>
<%- end %>

<%- action = ({{singular_resource_name}}.id ? "/{{pluralized_resource_name}}/" + {{singular_resource_name}}.id.to_s : "/{{pluralized_resource_name}}") %>
<form action="<%= action %>" method="post">
  <%= csrf_tag %>
  <%- if {{singular_resource_name}}.id %>
  <input type="hidden" name="_method" value="patch" />
  <%- end %>

  <div class="form-group">
    <%= text_field(name: "name", value: {{singular_resource_name}}.name, placeholder: "Name", class: "form-control") -%>
  </div>
  <%= submit("Submit", class: "btn btn-success btn-sm") -%>
  <%= link_to("Back", "/{{pluralized_resource_name}}", class: "btn btn-light btn-sm") -%>
</form>
```