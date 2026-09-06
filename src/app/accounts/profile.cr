require "json"

module App::Accounts
  # Platform-neutral validation shared by web, server adapters and native state.
  module DisplayName
    MAX_CHARACTERS =  64
    MAX_BYTES      = 256

    def self.normalize(value : String) : String
      raise ArgumentError.new("Display name must be valid text") unless value.valid_encoding?
      if value.bytesize > MAX_BYTES || value.each_codepoint.any? { |point| point < 32 || (127..159).includes?(point) }
        raise ArgumentError.new("Display name must be at most 64 characters without control characters")
      end
      normalized = value.strip
      raise ArgumentError.new("Display name must be at most 64 characters") if normalized.size > MAX_CHARACTERS
      normalized
    end
  end

  struct Profile
    include JSON::Serializable
    include JSON::Serializable::Strict

    getter id : Int64
    getter email : String
    getter account_type : String
    getter display_name : String

    def initialize(@id, @email, @account_type, @display_name)
    end

    def title : String
      @display_name.empty? ? @email : @display_name
    end

    def valid? : Bool
      @id > 0 && !@email.empty? && @email.bytesize <= 255 && @email.valid_encoding? &&
        {"regular", "admin"}.includes?(@account_type) && DisplayName.normalize(@display_name) == @display_name
    rescue ArgumentError
      false
    end
  end
end
