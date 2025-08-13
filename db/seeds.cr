require "../config/database"
require "../src/models/**"

# Create test users
admin = Admin.new
admin.email = "admin@example.com"
admin.password = "AdminPassword"
admin.password_confirmation = "AdminPassword"
admin.api_key = "test-api-key"
admin.api_secret = "test-api-secret"
admin.save!

user = User.new
user.email = "user@example.com"
user.password = "UserPassword"
user.password_confirmation = "UserPassword"
user.api_key = "test-api-key"
user.api_secret = "test-api-secret"
user.save!

api = Api.new
api.email = "api@example.com"
api.password = "ApiPassword"
api.password_confirmation = "ApiPassword"
api.api_key = "test-api-key"
api.api_secret = "test-api-secret"
api.save!

puts "Database seeded successfully!"