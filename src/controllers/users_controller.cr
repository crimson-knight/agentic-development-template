class UsersController < ApplicationController
  # GET /users
  def index
    users = User.all
    render "index.ecr"
  end

  # GET /users/:id
  def show
    if user = User.find_by(id: params[:id])
      render "show.ecr"
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end

  # GET /users/new
  def new
    user = User.new
    render "new.ecr"
  end

  # POST /users
  def create
    user = User.new(user_params)

    # Handle avatar upload
    if avatar = params.files["avatar"]?
      user.avatar = avatar.file
    end

    # Handle resume upload
    if resume = params.files["resume"]?
      user.resume = resume.file
    end

    if user.save
      redirect_to "/users/#{user.id}", flash: {"success" => "User created successfully!"}
    else
      flash.now["error"] = "Failed to create user: #{user.errors.full_messages.join(", ")}"
      render "new.ecr"
    end
  end

  # GET /users/:id/edit
  def edit
    if user = User.find_by(id: params[:id])
      render "edit.ecr"
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end

  # PATCH /users/:id
  def update
    if user = User.find_by(id: params[:id])
      # Update basic attributes
      user.assign_attributes(user_params)

      # Handle avatar upload
      if avatar = params.files["avatar"]?
        user.avatar = avatar.file
      end

      # Handle resume upload
      if resume = params.files["resume"]?
        user.resume = resume.file
      end

      # Handle file removal
      if params["remove_avatar"]? == "1"
        user.avatar.destroy if user.avatar
        user.avatar_data = nil
      end

      if params["remove_resume"]? == "1"
        user.resume.destroy if user.resume
        user.resume_data = nil
      end

      if user.save
        redirect_to "/users/#{user.id}", flash: {"success" => "User updated successfully!"}
      else
        flash.now["error"] = "Failed to update user: #{user.errors.full_messages.join(", ")}"
        render "edit.ecr"
      end
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end

  # DELETE /users/:id
  def destroy
    if user = User.find_by(id: params[:id])
      user.destroy
      redirect_to "/users", flash: {"success" => "User deleted successfully!"}
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end

  private def user_params
    params.validation do
      required(:email) { |v| v.email? }
      required(:first_name) { |v| v.str? && !v.str.empty? }
      required(:last_name) { |v| v.str? && !v.str.empty? }
      optional(:bio) { |v| v.str? }
      optional(:role) { |v| v.str? }
    end
  end
end
