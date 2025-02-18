# Index View Template & Instructions

1. Using the notes file, remind yourself of the attributes of the resource.

2. Using the template below, create the index view in the `src/views/{namespace}/#{controller_name}` directory with the file name `index.ecr`.

```crystal
# src/views/{namespace}/#{controller_name}/index.ecr
<div class="row">
  <div class="col-sm-11">
    <h2>{{pluralized_resource_name}}</h2>
  </div>
  <div class="col-sm-1">
    <a class="btn btn-success btn-sm" href="/{{pluralized_resource_name}}/new">New</a>
  </div>
</div>

<div class="table-responsive">
  <table class="table table-striped">
    <thead>
      <tr>
        <%- {{singular_resource_name}}.attributes.each do |attribute| %>
          <th><%= attribute.name %></th>
        <%- end %>
        <th>Actions</th>
      </tr>
    <tbody>
    <%- {{pluralized_resource_name}}.each do |{{singular_resource_name}}| %>
      <tr>
        <td><%= {{singular_resource_name}}.{{attribute_name_from_model}} %></td>
        <td>
          <span>
            <%= link_to("Show", "/{{pluralized_resource_name}}/#{{singular_resource_name}}.id", class: "btn btn-info btn-sm") -%>
            <%= link_to("Edit", "/{{pluralized_resource_name}}/#{{singular_resource_name}}.id/edit", class: "btn btn-success btn-sm") -%>
            <%= link_to("Delete", "/{{pluralized_resource_name}}/#{{singular_resource_name}}.id?_csrf=#{csrf_token}", "data-method": "delete", "data-confirm": "Are you sure?", class: "btn btn-danger btn-sm") -%>
          </span>
        </td>
      </tr>
    <%- end %>
    </tbody>
  </table>
</div>
```