require "./spec_helper"

describe LoginController do
  describe "LoginController#new" do
    it "renders the view" do
      HTTP::Client.get("http://localhost:3000/login/new") do |response|
        response.status.should eq(HTTP::Status::OK)
      end
    end
  end

  describe "LoginController#create" do
    it "renders the view" do
      HTTP::Client.post("http://localhost:3000/login/create", body: "username=test@example.com&password=password") do |response|
        response.status.should eq(HTTP::Status::FOUND)
      end
    end
  end
  
  describe "LoginController#destroy" do
    it "renders the view" do
    end
  end
end
