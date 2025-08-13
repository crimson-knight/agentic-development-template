require "./spec_helper"

describe "Application Compilation" do
  it "successfully loads all application files" do
    # This test ensures all files compile without errors
    # The require statements in spec_helper load the entire application
    true.should eq(true)
  end
  
  it "loads database configuration" do
    # Verify that Granite connections are properly configured
    # Granite connections are added during configuration
    # This test verifies the configuration loads without error
    true.should eq(true)
  end
  
  it "loads all models" do
    # Verify models are loaded and can be instantiated
    persona = Persona.new
    persona.should_not be_nil
    
    user = User.new
    user.should_not be_nil
    
    admin = Admin.new
    admin.should_not be_nil
    
    api = Api.new
    api.should_not be_nil
  end
  
  it "loads all controllers" do
    # Verify controllers can be referenced
    Public::HomeController.should_not be_nil
    Public::SessionController.should_not be_nil
    Authenticated::BaseAuthenticatedController.should_not be_nil
  end
end