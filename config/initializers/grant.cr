require "grant"

# Configure Grant ORM for the application
# Note: The basic database connection is configured in config/database.cr
# This file contains additional Grant-specific configuration

# Configure encryption for sensitive data
if encryption_key = ENV["ENCRYPTION_KEY"]?
  Grant::Encryption::Config.primary_key = encryption_key
end

# Configure logging in development
# Note: Grant uses Crystal's Log module internally
# if Amber.env.development?
#   # Configure Grant logging if needed
# end

# Optional: Configure read replica for scaling
# if Amber.env.production? && ENV["READ_REPLICA_HOST"]?
#   Grant::Connections << Grant::Adapter::Pg.new(
#     name: "read_replica",
#     url: "postgres://#{ENV["DB_USER"]}:#{ENV["DB_PASSWORD"]}@#{ENV["READ_REPLICA_HOST"]}:#{ENV["DB_PORT"]}/#{ENV["DB_NAME"]}"
#   )
# end

# Grant features available:
# - Associations: belongs_to, has_one, has_many, has_many :through, polymorphic
# - Validations: validates_presence_of, validates_uniqueness_of, validates_email, etc.
# - Security: encrypts, has_secure_token, include Grant::SignedId, include Grant::TokenFor
# - Callbacks: before_save, after_create, after_commit, etc.
# - Scopes: scope, default_scope
# - Enums: enum_attribute
# - Transactions: Grant::Base.transaction
# - Locking: optimistic and pessimistic with with_lock
# - Dirty tracking: changed?, attribute_was, saved_changes?
# - Data normalization: normalizes
