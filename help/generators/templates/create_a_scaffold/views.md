# Scaffold View Templates

Use these templates to create views for a scaffolded resource. Replace placeholder values as needed.

## Index View Template

```ecr
<!-- src/views/{{plural_resource_name}}/index.ecr -->
<div class="row">
  <div class="col-sm-11">
    <h2>{{display_name_plural}}</h2>
  </div>
  <div class="col-sm-1">
    <a class="btn btn-success btn-sm" href="/{{plural_resource_name}}/new">New</a>
  </div>
</div>

<div class="table-responsive">
  <table class="table table-striped">
    <thead>
      <tr>
        <!-- Add column headers for each attribute -->
        <th>Name</th>
        <th>Description</th>
        <th>Actions</th>
      </tr>
    <tbody>
    <%- {{plural_resource_name}}.each do |{{singular_resource_name}}| %>
      <tr>
        <!-- Add a cell for each attribute -->
        <td><%= {{singular_resource_name}}.name %></td>
        <td><%= {{singular_resource_name}}.description %></td>
        <td>
          <span>
            <%= link_to("Show", "/{{plural_resource_name}}/#{{{singular_resource_name}}.id}", class: "btn btn-info btn-sm") -%>
            <%= link_to("Edit", "/{{plural_resource_name}}/#{{{singular_resource_name}}.id}/edit", class: "btn btn-success btn-sm") -%>
            <%= link_to("Delete", "/{{plural_resource_name}}/#{{{singular_resource_name}}.id}?_csrf=#{csrf_token}", "data-method": "delete", "data-confirm": "Are you sure?", class: "btn btn-danger btn-sm") -%>
          </span>
        </td>
      </tr>
    <%- end %>
    </tbody>
  </table>
</div>
```

## Show View Template

```ecr
<!-- src/views/{{plural_resource_name}}/show.ecr -->
<h1>Show {{display_name}}</h1>

<div class="card">
  <div class="card-body">
    <!-- Add a display line for each attribute -->
    <p><strong>Name:</strong> <%= {{singular_resource_name}}.name %></p>
    <p><strong>Description:</strong> <%= {{singular_resource_name}}.description %></p>
    <!-- Add more attributes as needed -->
  </div>
</div>

<div class="mt-4">
  <%= link_to("Back", "/{{plural_resource_name}}", class: "btn btn-light btn-sm") -%>
  <%= link_to("Edit", "/{{plural_resource_name}}/#{{{singular_resource_name}}.id}/edit", class: "btn btn-success btn-sm") -%>
  <%= link_to("Delete", "/{{plural_resource_name}}/#{{{singular_resource_name}}.id}?_csrf=#{csrf_token}", "data-method": "delete", "data-confirm": "Are you sure?", class: "btn btn-danger btn-sm") -%>
</div>
```

## New View Template

```ecr
<!-- src/views/{{plural_resource_name}}/new.ecr -->
<h1>New {{display_name}}</h1>

<%= render(partial: "_form.ecr") %>
```

## Edit View Template

```ecr
<!-- src/views/{{plural_resource_name}}/edit.ecr -->
<h1>Edit {{display_name}}</h1>

<%= render(partial: "_form.ecr") %>
```

## Form Partial Template

```ecr
<!-- src/views/{{plural_resource_name}}/_form.ecr -->
<%- if {{singular_resource_name}}.errors %>
  <ul class="errors">
  <%- {{singular_resource_name}}.errors.each do |error| %>
    <li><%= error.to_s %></li>
  <%- end %>
  </ul>
<%- end %>

<%- action = ({{singular_resource_name}}.id ? "/{{plural_resource_name}}/" + {{singular_resource_name}}.id.to_s : "/{{plural_resource_name}}") %>
<form action="<%= action %>" method="post">
  <%= csrf_tag %>
  <%- if {{singular_resource_name}}.id %>
  <input type="hidden" name="_method" value="patch" />
  <%- end %>

  <!-- Add form fields for each attribute -->
  <div class="form-group">
    <label for="name">Name</label>
    <%= text_field(name: "name", value: {{singular_resource_name}}.name, placeholder: "Name", class: "form-control") -%>
  </div>
  
  <div class="form-group">
    <label for="description">Description</label>
    <%= text_area(name: "description", content: {{singular_resource_name}}.description, placeholder: "Description", class: "form-control") -%>
  </div>
  
  <!-- Add more form fields for other attributes -->
  
  <div class="form-group mt-4">
    <%= submit("Submit", class: "btn btn-success btn-sm") -%>
    <%= link_to("Back", "/{{plural_resource_name}}", class: "btn btn-light btn-sm") -%>
  </div>
</form>
``` 