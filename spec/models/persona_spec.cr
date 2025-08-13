require "../spec_helper"
require "crypto/bcrypt/password"

describe Persona do
  describe "initialization" do
    it "creates a new persona" do
      persona = Persona.new
      persona.should_not be_nil
      persona.type.should eq("User")
    end
    
    it "sets default values" do
      persona = Persona.new
      persona.type.should eq("User")
      persona.new_record?.should be_true
    end
  end
  
  describe "authentication" do
    it "can set and verify passwords" do
      persona = Persona.new
      persona.email = "test@example.com"
      persona.password = "password123"
      
      # Manually trigger password hashing for test
      persona.password_digest = Crypto::Bcrypt::Password.create("password123").to_s
      
      # Test authentication method
      result = persona.authenticate("password123")
      result.should_not be_nil
      
      wrong = persona.authenticate("wrong")
      wrong.should be_nil
    end
  end
  
  describe "factory methods" do
    it "creates User type personas" do
      user = User.new
      user.should_not be_nil
      user.type.should eq("User")
    end
    
    it "creates Admin type personas" do
      admin = Admin.new
      admin.should_not be_nil
      admin.type.should eq("Admin")
    end
    
    it "creates Api type personas" do
      api = Api.new
      api.should_not be_nil
      api.type.should eq("Api")
    end
  end
end