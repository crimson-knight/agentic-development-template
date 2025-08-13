require "../spec_helper"

describe "Authentication Pipes" do
  describe "HTTP::Server::Context extension" do
    it "adds current_user property" do
      context = HTTP::Server::Context.new(
        HTTP::Request.new("GET", "/"),
        HTTP::Server::Response.new(IO::Memory.new)
      )
      
      context.current_user.should be_nil
      
      # Can set a user
      user = User.new
      context.current_user = user
      context.current_user.should eq(user)
    end
  end
  
  describe CurrentUserPipe do
    it "can be instantiated" do
      pipe = CurrentUserPipe.new
      pipe.should_not be_nil
    end
  end
  
  describe AuthenticateUser do
    it "can be instantiated" do
      pipe = AuthenticateUser.new
      pipe.should_not be_nil
    end
  end
end