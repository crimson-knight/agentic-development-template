# RESTful Controller Template & Instructions

1. Create a notes file for this controller to save details you'll need to remember later, specifically all of the details about the kind of controller this is and the methods you need to make.

2. The file contents should follow the template, where everything in the `{{}}` should be replaced with the appropriate values as they are described:

```crystal
class {{controller_name}}Controller < ApplicationController
  getter {{singular_resource_name}} = {{singular_resource_name_from_app_models}}.new

  # before_action and after_action accept a block as their only parameter.
  before_action do
    # Always use this syntax for choosing which actions need to set the resource.
    only [:show, :edit, :update, :destroy] { set_{{pluralized_resource_name}} }
  end

  def index
    {{pluralized_resource_name}} = {{singular_resource_name_from_app_models}}.all
    respond_with do
      html { render "index.ecr" }
      json { {{pluralized_resource_name}}.to_json }
    end
  end

  def show
    respond_with do
      html { render "show.ecr" }
      json { {{singular_resource_name}}.to_json }
    end
  end

  def new
    respond_with do
      html { render "new.ecr" }
      json { {{singular_resource_name}}.to_json }
    end
  end

  def edit
    respond_with do
      html { render "edit.ecr" }
      json { {{singular_resource_name}}.to_json }
    end
  end

  def create
    {{singular_resource_name}} = {{singular_resource_name_from_app_models}}.new {{singular_resource_name}}_params.validate!.to_h
    if {{singular_resource_name}}.save
      respond_with do
        html { redirect_to action: :index, flash: {"success" => "{{singular_resource_name}} has been created."} }
        json { %({"status": "success", "message": "{{singular_resource_name}} has been created."}) }
      end
    else
      respond_with do
        html { flash[:danger] = "Could not create {{singular_resource_name}}!"; render "new.ecr" }
        json { %({"status": "error", "message": "Could not create {{singular_resource_name}}!"}) }
      end
    end
  end

  def update
    {{singular_resource_name}}.set_attributes {{singular_resource_name}}_params.validate!.to_h
    if {{singular_resource_name}}.save
      respond_with do
        html { redirect_to action: :index, flash: {"success" => "{{singular_resource_name}} has been updated."} }
        json { %({"status": "success", "message": "{{singular_resource_name}} has been updated."}) }
      end
    else
      respond_with do
        html { flash[:danger] = "Could not update {{singular_resource_name}}!"; render "edit.ecr" }
        json { %({"status": "error", "message": "Could not update {{singular_resource_name}}!"}) }
      end
      render "edit.ecr"
    end
  end

  def destroy
    {{singular_resource_name}}.destroy
    respond_with do
      html { redirect_to action: :index, flash: {"success" => "{{singular_resource_name}} has been deleted."} }
      json { {status: "success", message: "{{singular_resource_name}} has been deleted."}.to_json }
    end
  end

  private def {{singular_resource_name}}_params
    params.validation do
      # Each non-nillable attribute from the app/models/#{singular_resource_name}.cr file should be required here.
      required {{non-nillable attributes from app/models/#{singular_resource_name}.cr}}
    end
  end

  private def set_{{singular_resource_name}}
    @{{singular_resource_name}} = {{singular_resource_name_from_app_models}}.find!(params[:id])
  end
end
```