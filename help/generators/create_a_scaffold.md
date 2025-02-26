# Create A Scaffold

## Prerequisites

Required:
- The name of the resource to scaffold
- The attributes of the resource with their types

Optional:
- Any relationships with other models
- Any specific validation requirements
- Custom UI requirements
- Authorization requirements

Review the information that you have been provided to ensure it includes all of the required information.
If there is any missing information or vague information, prompt the user for the missing information before proceeding.

## Steps

1. Create the model file in `src/models` directory using the following template:

```crystal
# src/models/{{singular_model_name}}.cr
class {{singular_model_name}} < Granite::Base
  connection pg  # or mysql depending on database.yml
  table {{plural_model_name}}

  column id : Int64, primary: true
  # Add each attribute here using the following syntax:
  # column attribute_name : Type
  column name : String?
  column age : Int32?
  
  # Add timestamps for created_at and updated_at
  timestamps

  # Add any relationships here
  # has_many :related_models
  # belongs_to :parent_model
  
  # Add any validations here
  # validate :name, "Name is required", ->(user : User) do
  #   (name != nil && !name.to_s.empty?)
  # end
end
```

2. Create the controller in `src/controllers` directory:

```crystal
# src/controllers/{{plural_model_name}}_controller.cr
class {{plural_model_name}}Controller < ApplicationController
  getter {{singular_model_name}} = {{singular_model_name}}.new

  before_action do
    only [:show, :edit, :update, :destroy] { set_{{singular_model_name}} }
  end

  def index
    {{plural_model_name}} = {{singular_model_name}}.all
    render "index.ecr"
  end

  def show
    render "show.ecr"
  end

  def new
    render "new.ecr"
  end

  def edit
    render "edit.ecr"
  end

  def create
    {{singular_model_name}} = {{singular_model_name}}.new {{singular_model_name}}_params.validate!
    if {{singular_model_name}}.save
      redirect_to action: :index, flash: {"success" => "{{display_name}} has been created."}
    else
      flash[:danger] = "Could not create {{display_name}}!"
      render "new.ecr"
    end
  end

  def update
    {{singular_model_name}}.set_attributes {{singular_model_name}}_params.validate!
    if {{singular_model_name}}.save
      redirect_to action: :index, flash: {"success" => "{{display_name}} has been updated."}
    else
      flash[:danger] = "Could not update {{display_name}}!"
      render "edit.ecr"
    end
  end

  def destroy
    {{singular_model_name}}.destroy
    redirect_to action: :index, flash: {"success" => "{{display_name}} has been deleted."}
  end

  private def {{singular_model_name}}_params
    params.validation do
      # Add parameter validations here
      required :name
      required :age
    end
  end

  private def set_{{singular_model_name}}
    @{{singular_model_name}} = {{singular_model_name}}.find! params[:id]
  end
end
```

3. Create the views in `src/views/{{plural_model_name}}` directory:

Form partial (`_form.ecr`):
```ecr
<%- if {{singular_model_name}}.errors %>
  <ul class="errors">
  <%- {{singular_model_name}}.errors.each do |error| %>
    <li><%= error.to_s %></li>
  <%- end %>
  </ul>
<%- end %>

<%- action = ({{singular_model_name}}.id ? "/{{plural_model_name}}/" + {{singular_model_name}}.id.to_s : "/{{plural_model_name}}") %>
<form action="<%= action %>" method="post">
  <%= csrf_tag %>
  <%- if {{singular_model_name}}.id %>
  <input type="hidden" name="_method" value="patch" />
  <%- end %>

  <div class="form-group">
    <%= text_field(name: "name", value: {{singular_model_name}}.name, placeholder: "Name", class: "form-control") -%>
  </div>
  <div class="form-group">
    <%= text_field(name: "age", value: {{singular_model_name}}.age, placeholder: "Age", class: "form-control") -%>
  </div>
  <%= submit("Submit", class: "btn btn-success btn-sm") -%>
  <%= link_to("Back", "/{{plural_model_name}}", class: "btn btn-light btn-sm") -%>
</form>
```

Index view (`index.ecr`):
```ecr
<div class="row">
  <div class="col-sm-11">
    <h2>{{display_name_plural}}</h2>
  </div>
  <div class="col-sm-1">
    <a class="btn btn-success btn-sm" href="/{{plural_model_name}}/new">New</a>
  </div>
</div>

<div class="table-responsive">
  <table class="table table-striped">
    <thead>
      <tr>
        <th>Name</th>
        <th>Age</th>
        <th>Actions</th>
      </tr>
    <tbody>
    <%- {{plural_model_name}}.each do |{{singular_model_name}}| %>
      <tr>
        <td><%= {{singular_model_name}}.name %></td>
        <td><%= {{singular_model_name}}.age %></td>
        <td>
          <span>
            <%= link_to("Show", "/{{plural_model_name}}/#{{{singular_model_name}}.id}", class: "btn btn-info btn-sm") -%>
            <%= link_to("Edit", "/{{plural_model_name}}/#{{{singular_model_name}}.id}/edit", class: "btn btn-success btn-sm") -%>
            <%= link_to("Delete", "/{{plural_model_name}}/#{{{singular_model_name}}.id}?_csrf=#{csrf_token}", "data-method": "delete", "data-confirm": "Are you sure?", class: "btn btn-danger btn-sm") -%>
          </span>
        </td>
      </tr>
    <%- end %>
    </tbody>
  </table>
</div>
```

4. Create the migration file in `db/migrations` directory:

```sql
-- +micrate Up
CREATE TABLE {{plural_model_name}} (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR,
  age INT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- +micrate Down
DROP TABLE IF EXISTS {{plural_model_name}};
```

5. Update the navigation in `src/views/layouts/_nav.ecr`:

```ecr
<%- active = context.request.path == "/{{plural_model_name}}" %>
<%= link_to("{{display_name_plural}}", "/{{plural_model_name}}", class: active ? "nav-link active" : "nav-link") %>
```

## Common Customization Points

1. Views
   - Customize form layout and styling
   - Add field validations and error displays
   - Customize index table columns
   - Add search and filtering

2. Controller
   - Add authentication checks
   - Customize flash messages
   - Add sorting and pagination
   - Add custom actions

3. Model
   - Add relationships
   - Add validations
   - Add scopes and queries
   - Add callbacks

4. Routes
   - Add custom routes
   - Add nested resources
   - Add member/collection routes
``` 