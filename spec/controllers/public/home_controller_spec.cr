require "../../spec_helper"

describe Public::HomeController do
  describe "compilation" do
    it "controller class exists and can be referenced" do
      Public::HomeController.should_not be_nil
    end
  end
  
  # Note: Full controller testing would require HTTP context setup
  # This test ensures the controller compiles correctly
end