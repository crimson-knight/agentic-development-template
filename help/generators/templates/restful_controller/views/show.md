# Show View Template & Instructions

1. Using the notes file, remind yourself of the attributes of the resource.

2. Using the template below, create the show view in the `src/views/{namespace}/#{controller_name}` directory with the file name `show.ecr`.


```crystal
# src/views/{namespace}/#{controller_name}/show.ecr
<h1>Show {{singular_resource_name}}</h1>

<p><%= {{singular_resource_name}}.{{first_attribute_name_from_model}} %></p>
<p>
  <%= link_to("Back", "/{{pluralized_resource_name}}", class: "btn btn-light btn-sm") -%>
  <%= link_to("Edit", "/{{pluralized_resource_name}}/#{{singular_resource_name}}.id/edit", class: "btn btn-success btn-sm") -%>
  <%= link_to("Delete", "/{{pluralized_resource_name}}/#{{singular_resource_name}}.id?_csrf=#{csrf_token}", "data-method": "delete", "data-confirm": "Are you sure?", class: "btn btn-danger btn-sm") -%>
</p>
```