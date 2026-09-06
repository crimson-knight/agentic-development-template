require "spec"
require "../../src/app/accounts/profile"

describe App::Accounts::DisplayName do
  it "normalizes surrounding spaces and preserves international text" do
    App::Accounts::DisplayName.normalize("  Android 雪 😀 é  ").should eq "Android 雪 😀 é"
    App::Accounts::DisplayName.normalize("   ").should eq ""
    App::Accounts::DisplayName.normalize("😀" * 64).should eq "😀" * 64
  end

  it "rejects overlong, invalid UTF-8 and control-character input" do
    ["a" * 65, "😀" * 65, "line\nnext", "\u007f", "\u0085", String.new(Bytes[0xff])].each do |value|
      expect_raises(ArgumentError) { App::Accounts::DisplayName.normalize(value) }
    end
  end
end

describe App::Accounts::Profile do
  it "round-trips a platform-neutral account and validates its contents" do
    profile = App::Accounts::Profile.new(1_i64, "native@example.test", "regular", "Android 雪")
    restored = App::Accounts::Profile.from_json(profile.to_json)
    restored.valid?.should be_true
    restored.title.should eq "Android 雪"
    App::Accounts::Profile.new(1_i64, "native@example.test", "admin", "").title.should eq "native@example.test"
  end

  it "does not accept invalid account identity, role or unnormalized name" do
    [{0_i64, "valid@example.test", "regular", ""},
     {1_i64, "", "regular", ""},
     {1_i64, "valid@example.test", "root", ""},
     {1_i64, "valid@example.test", "admin", " spaces "}].each do |values|
      App::Accounts::Profile.new(*values).valid?.should be_false
    end
    expect_raises(JSON::SerializableError) do
      App::Accounts::Profile.from_json(%({"id":1,"email":"e","account_type":"regular","display_name":"","password":"no"}))
    end
  end
end
