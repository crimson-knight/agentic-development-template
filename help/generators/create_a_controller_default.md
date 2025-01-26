# Create A Controller

## Verify the necessary information is provided

Required:
- You have been provided with the name of the controller.

Optional:
- You have been given a list of the methods or routes that need to be implemented.
- You have been given the name of a resource to create a controller for.

If you do not have all of the required information, please ask the user for the missing information before continuing.

## Create The Necessary Files

1. Create the controller file in the `src/controllers` directory, 
    1a. It will be named the pluralized version of the resource name if a resource was provided `src/controllers/#{pluralized_resource_name}_controller.cr`
    1b. It will be named the controller name if no resource was provided `src/controllers/#{controller name}_controller.cr`
    1c. The controller will inherit from `ApplicationController`, unless the route is already namespaced to a specific parent controller.
    1d. All controllers that inherit from `ApplicationController` have access to a `current_user` method that returns the current `User` object, this must be used in a conditional assignment to remove the `Nil` from the type union. Another helper method is `logged_in?` that returns a boolean if the user is not logged in.
    1e. If creating a RESTful controller, use the `help/generators/templates/restful_controller.md` file instructions and template.
    1f. If create a non-RESTful controller, use the `help/generators/templates/non_restful_controller.md` file instructions and template.

2. Create the route in the `config/routes.cr` file
  2a. If a resource is provided, the route will be namespaced to the resource using the `resources` method, under the `web` route grouping.
  2b. If no resource is provided, the route will be added to the `ApplicationController` using the `get`, `post`, `put`, `patch`, or `delete` methods, defaulting to `get` if the user does not specify in the prompt.
  2c. If a route must be restricted to authenticated users, the route will be added to the `auth` route grouping. Authentication is already handled for all controllers in this route group, do not add a `before_action` to authenticate the user.

```crystal
  routes :web do
    # example of a resource route
    resources "/{{pluralized_resource_name}}", {{controller_name}}Controller

    # example of a non-resource route where the name `login` was provided for the route
    get "/login", LoginController, :new
  end
```

3. Create the views in the `src/views/#{controller_name}` directory
  3a. The current user can 

```crystal
# src/views/#{controller_name}/_form.ecr
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

```crystal
# src/views/#{controller_name}/index.ecr
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

```crystal
# src/views/#{controller_name}/show.ecr
<h1>Show {{singular_resource_name}}</h1>

<p><%= {{singular_resource_name}}.{{first_attribute_name_from_model}} %></p>
<p>
  <%= link_to("Back", "/{{pluralized_resource_name}}", class: "btn btn-light btn-sm") -%>
  <%= link_to("Edit", "/{{pluralized_resource_name}}/#{{singular_resource_name}}.id/edit", class: "btn btn-success btn-sm") -%>
  <%= link_to("Delete", "/{{pluralized_resource_name}}/#{{singular_resource_name}}.id?_csrf=#{csrf_token}", "data-method": "delete", "data-confirm": "Are you sure?", class: "btn btn-danger btn-sm") -%>
</p>
```

```crystal
# src/views/#{controller_name}/new.ecr
<h1>New {{singular_resource_name}}</h1>

<%= render(partial: "_form.ecr") %>
```

```crystal
# src/views/#{controller_name}/edit.ecr
<h1>Edit {{singular_resource_name}}</h1>

<%= render(partial: "_form.ecr") %>
```

4. Update  the navigation in the `src/views/layouts/_nav_.ecr` file to include a link to the index page of the controller
  4a. If a resource was _not_ provided, then skip this step entirely.

```crystal
# src/views/layouts/_nav_.ecr
# 
# Add the following to the navigation:
<%- active = context.request.path == "/{{pluralized_resource_name}}" ? "active" : "" %>
<li class="nav-item <%= active %>">
  <a class="nav-link" href="/{{pluralized_resource_name}}">{{pluralized_resource_name}}</a>
</li>
```

5. Review the help/generators/validations/controller_methods_validation.md file and your controller file to ensure that all of the necessary methods are implemented correctly.
