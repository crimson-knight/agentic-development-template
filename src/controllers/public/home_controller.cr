require "../../components/pages/home_page_component"
require "../../components/layouts/application_layout"

class Public::HomeController < ApplicationController
  def index
    # Build page component
    page = Components::Pages::HomePageComponent.new(
      logged_in: logged_in?.to_s
    )

    # Wrap in layout
    layout = Components::Layouts::ApplicationLayout.new(
      title: "AgentC - Modern Crystal Web Application Template",
      content: page.render,
      current_path: request.path,
      logged_in: logged_in?.to_s,
      user_email: get_current_user.try(&.email),
      flash_success: flash[:success]?,
      flash_error: flash[:danger]?,
      flash_info: flash[:info]?
    )

    context.response.content_type = "text/html"
    context.response.print layout.render
  end
end
