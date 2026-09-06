require "spec"
require "../src/app/counter"

describe App::Counter do
  it "shares validation and state without a server or renderer dependency" do
    state = App::Counter.new
    state.increment.should eq(1)
    state.rename("Android").should be_true
    state.rename("x").should be_false
    state.name.should eq("Android")
  end

  it "restores a validated versioned snapshot atomically" do
    source = App::Counter.new
    source.increment
    source.rename("Android")
    restored = App::Counter.new
    restored.restore(source.snapshot).should be_true
    restored.count.should eq(1)
    restored.name.should eq("Android")
    [%({"version":2,"name":"New","count":9}), %({"version":1,"name":"x","count":9}),
     %({"version":1,"name":"New","count":-1}), %({"version":1,"name":"New","count":2147483648}),
     %({"version":1,"name":"New","count":"1"}), %({"name":"New","count":1}), "null", "invalid"].each do |invalid|
      restored.restore(invalid).should be_false
      restored.snapshot.should eq(source.snapshot)
    end
  end
end
