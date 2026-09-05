require "../spec_helper"

describe "Persona account field validation" do
  it "keeps profile and session fields on Jennifer's existing single table" do
    User.table_name.should eq("personas")
    Admin.table_name.should eq("personas")
    User.new.display_name.should eq("")
    User.new.session_version.should eq("")
  end

  it "accepts a Unicode password at the actual bcrypt byte boundary" do
    password = "é" * 35 + "x"
    user = User.new({email: "unicode@example.test", password: password, password_confirmation: password, api_key: "", api_secret: ""})
    user.save.should be_true
    User.find!(user.id).authenticate(password).should_not be_nil
  end

  it "rejects Unicode passwords beyond that boundary before persistence" do
    password = "é" * 36
    user = User.new({email: "unicode@example.test", password: password, password_confirmation: password, api_key: "", api_secret: ""})
    user.save.should be_false
    user.errors[:password].should_not be_empty
  end

  it "rejects overlong display names even outside the controller" do
    user = User.new({email: "name@example.test", display_name: "a" * 101, password: "password123", password_confirmation: "password123", api_key: "", api_secret: ""})
    user.save.should be_false
    user.errors[:display_name].should_not be_empty
  end

  it "does not require a password resubmission for a persisted profile update" do
    user = User.create!({email: "profile@example.test", password: "password123", password_confirmation: "password123", api_key: "", api_secret: ""})
    loaded = User.find!(user.id)
    loaded.password.should be_nil
    loaded.display_name = "Fixture Name"
    loaded.save.should be_true
    User.find!(user.id).authenticate("password123").should_not be_nil
  end
end
