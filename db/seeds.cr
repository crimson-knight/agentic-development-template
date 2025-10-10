require "../config/application"
require "../src/models/**"

# Database seeding script for Grant ORM
puts "Starting database seeding..."

# Create admin user
admin = Admin.new
admin.email = "admin@example.com"
admin.password = "AdminPassword"
admin.password_confirmation = "AdminPassword"
admin.api_key = "test-admin-api-key"
admin.api_secret = "test-admin-api-secret"
admin.type = "Admin"

if admin.save
  puts "✓ Created admin user: #{admin.email}"
else
  puts "✗ Failed to create admin user"
  admin.errors.each do |error|
    puts "  - #{error}"
  end
end

# Create regular user
user = User.new
user.email = "user@example.com"
user.password = "UserPassword"
user.password_confirmation = "UserPassword"
user.api_key = "test-user-api-key"
user.api_secret = "test-user-api-secret"
user.type = "User"

if user.save
  puts "✓ Created regular user: #{user.email}"
else
  puts "✗ Failed to create regular user"
  user.errors.each do |error|
    puts "  - #{error}"
  end
end

# Create API user
api_user = Api.new
api_user.email = "api@example.com"
api_user.password = "ApiPassword"
api_user.password_confirmation = "ApiPassword"
api_user.api_key = "test-api-key"
api_user.api_secret = "test-api-secret"
api_user.type = "Api"

if api_user.save
  puts "✓ Created API user: #{api_user.email}"
else
  puts "✗ Failed to create API user"
  api_user.errors.each do |error|
    puts "  - #{error}"
  end
end

puts "Database seeding completed!"