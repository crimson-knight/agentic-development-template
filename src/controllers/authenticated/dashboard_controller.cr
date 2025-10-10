require "../../components/pages/dashboard_component"
require "../../components/layouts/application_layout"

class Authenticated::DashboardController < ApplicationController
  def index
    # Build dashboard component
    dashboard = Components::Pages::DashboardComponent.new

    # Wrap in layout
    layout = Components::Layouts::ApplicationLayout.new(
      title: "Dashboard - AgentC",
      content: dashboard.render,
      current_path: request.path,
      logged_in: "true",
      user_email: get_current_user.try(&.email),
      flash_success: flash[:success]?,
      flash_error: flash[:danger]?,
      flash_info: flash[:info]?
    )

    context.response.content_type = "text/html"
    context.response.print layout.render
  end
end
