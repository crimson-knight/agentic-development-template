require "amber/native"

module App
  class NameSchema < Amber::Schema::Definition
    field :name, String, required: true, min_length: 2, max_length: 64
  end

  # The same use case and store are shared by web and Android entrypoints.
  class Counter
    getter count = 0
    getter name = "Guest"

    def increment : Int32
      @count += 1
    end

    def rename(value : String) : Bool
      schema = NameSchema.new({"name" => JSON::Any.new(value.strip)})
      return false unless schema.validate.success?
      @name = schema.name.not_nil!
      true
    end

    def snapshot : String
      {version: 1, name: @name, count: @count}.to_json
    end

    # Validate the complete versioned snapshot before changing live state.
    def restore(snapshot : String) : Bool
      data = JSON.parse(snapshot).as_h
      return false unless data.keys.sort == ["count", "name", "version"]
      return false unless data["version"].as_i64 == 1
      name = data["name"].as_s
      count = data["count"].as_i64
      return false unless 0 <= count <= Int32::MAX
      return false unless name == name.strip && NameSchema.new({"name" => JSON::Any.new(name)}).validate.success?
      @name = name
      @count = count.to_i
      true
    rescue JSON::ParseException | TypeCastError | OverflowError
      false
    end
  end
end
