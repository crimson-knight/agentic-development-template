# Creating a Grant Model

This guide helps create Grant ORM models following best practices.

## Prerequisites
- Grant ORM is configured in `config/initializers/grant.cr`
- Database connection is established via `config/database.cr`
- Migrations are managed using Micrate (see `db/migrations/`)

## Basic Model Template

```crystal
require "grant"

class ModelName < Grant::Base
  connection pg
  table table_name

  # Primary key
  column id : Int64, primary: true

  # Add your columns here
  column name : String
  column email : String
  column active : Bool = true

  # Timestamps (created_at, updated_at)
  timestamps
end
```

## Instructions

1. Create a new file in the `src/models` directory with the name of the model (singular form, snake_case).
2. Add the code above, filling in `ModelName` (PascalCase) and `table_name` (plural, snake_case).
3. Add your column definitions with appropriate Crystal types.

## Adding Validations

```crystal
class User < Grant::Base
  connection pg
  table users

  column id : Int64, primary: true
  column email : String
  column name : String

  # Presence validations
  validates_presence_of :email, :name

  # Uniqueness validations
  validates_uniqueness_of :email

  # Format validations
  validates_email :email
  validates_format_of :name, with: /\A[a-zA-Z\s]+\z/

  # Length validations
  validates_length_of :name, minimum: 2, maximum: 100

  # Numericality validations
  validates_numericality_of :age, greater_than: 0, less_than: 150, allow_nil: true

  # Inclusion validations
  validates_inclusion_of :status, in: ["active", "inactive", "pending"]

  # Custom validations
  validate "custom rule" do |record|
    record.email.includes?("@")
  end

  timestamps
end
```

## Adding Associations

```crystal
class User < Grant::Base
  connection pg
  table users

  column id : Int64, primary: true

  # One-to-many
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :nullify

  # One-to-one
  has_one :profile, dependent: :destroy

  timestamps
end

class Post < Grant::Base
  connection pg
  table posts

  column id : Int64, primary: true
  column user_id : Int64
  column title : String

  # Many-to-one
  belongs_to :user

  # Many-to-many through join table
  has_many :taggings
  has_many :tags, through: :taggings

  timestamps
end
```

## Adding File Attachments with Gemma

```crystal
require "grant"
require "gemma/grant"

class User < Grant::Base
  include Gemma::Grant::Attachable
  include Gemma::Grant::AttachmentValidators

  connection pg
  table users

  column id : Int64, primary: true
  column name : String
  column avatar_data : JSON::Any?
  column documents_data : JSON::Any?

  # Single file attachment
  has_one_attached :avatar

  # Multiple file attachments
  has_many_attached :documents

  # File validations
  validate_file_size_of :avatar, maximum: 5.megabytes
  validate_content_type_of :avatar, accept: ["image/jpeg", "image/png"]

  timestamps
end
```

## Adding Security Features

```crystal
class User < Grant::Base
  connection pg
  table users

  column id : Int64, primary: true
  column email : String
  column ssn : String?
  column api_key : String?

  # Encrypted attributes
  encrypts :ssn

  # Secure random tokens
  has_secure_token :api_key

  # Signed IDs for secure URLs
  include Grant::SignedId

  # Token generation (e.g., for password reset)
  include Grant::TokenFor
  generates_token_for :password_reset, expires_in: 15.minutes do
    updated_at.to_s
  end

  # Data normalization
  normalizes :email, &.downcase.strip

  timestamps
end
```

## Adding Enum Attributes

```crystal
class Order < Grant::Base
  connection pg
  table orders

  column id : Int64, primary: true

  # Define enum
  enum Status
    Pending
    Processing
    Shipped
    Delivered
  end

  # Add enum attribute
  enum_attribute status : Status = :pending

  timestamps

  # Enum provides: order.pending?, order.processing!, Order.shipped.all
end
```

## Adding Callbacks

```crystal
class User < Grant::Base
  connection pg
  table users

  column id : Int64, primary: true
  column email : String
  column login_count : Int32 = 0

  # Before callbacks
  before_validation :normalize_email
  before_save :increment_login_count

  # After callbacks
  after_create :send_welcome_email
  after_save :update_search_index

  # Transaction callbacks
  after_commit :notify_external_service, on: :create

  timestamps

  private def normalize_email
    self.email = email.downcase.strip
  end

  private def increment_login_count
    self.login_count += 1
  end

  private def send_welcome_email
    puts "Sending welcome email to #{email}"
  end
end
```

## Adding Scopes

```crystal
class User < Grant::Base
  connection pg
  table users

  column id : Int64, primary: true
  column active : Bool = true
  column role : String = "member"

  # Simple scopes
  scope :active, ->{ where(active: true) }
  scope :admins, ->{ where(role: "admin") }

  # Parameterized scopes
  scope :created_after, ->(date : Time) { where.gteq(:created_at, date) }

  # Default scope
  default_scope ->{ where(active: true) }

  timestamps
end

# Usage: User.active.all, User.admins, User.created_after(7.days.ago)
```

## Creating Migrations

### 1. Create Migration File

```bash
# Create migration file manually in db/migrations/
# Format: YYYYMMDDHHmmss_description.sql
touch db/migrations/20250110120000_create_users.sql
```

### 2. Write Migration SQL

```sql
-- db/migrations/20250110120000_create_users.sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  bio TEXT,
  active BOOLEAN DEFAULT true,
  login_count INTEGER DEFAULT 0,
  last_login_at TIMESTAMP,
  avatar_data JSONB,
  resume_data JSONB,
  ssn VARCHAR(255),
  auth_token VARCHAR(255),
  role VARCHAR(50) DEFAULT 'member',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE UNIQUE INDEX idx_users_auth_token ON users(auth_token);
```

### 3. Run Migration

```bash
./migrate.sh
```

## Column Type Reference

Grant uses standard Crystal types mapped to PostgreSQL:

| Crystal Type | PostgreSQL Type | Example |
|--------------|-----------------|---------|
| Int32 | INTEGER | Default for numbers |
| Int64 | BIGINT | IDs, large numbers |
| Int16 | SMALLINT | Small numbers |
| String | VARCHAR/TEXT | Text data |
| Bool | BOOLEAN | true/false |
| Time | TIMESTAMP | Dates and times |
| Float32 | REAL | Single precision |
| Float64 | DOUBLE PRECISION | Double precision |
| JSON::Any | JSONB | JSON data |
| Bytes | BYTEA | Binary data |

**Optional values:** Add `?` to the type: `column bio : String?`
**Default values:** Use `=`: `column active : Bool = true`

## Complete Example

See `src/models/user.cr` for a comprehensive example demonstrating all Grant features including:
- Associations
- Validations
- Security features (encrypts, has_secure_token, SignedId, TokenFor)
- File attachments with Gemma
- Enum attributes
- Callbacks
- Scopes
- Data normalization

## Next Steps

1. Create the model file: `src/models/your_model.cr`
2. Create a migration: `db/migrations/YYYYMMDD_create_your_model.sql`
3. Run the migration: `./migrate.sh`
4. Test in console: `crystal run --error-trace src/your_app.cr`
5. Create controller: See `src/controllers/i_want_to_create_a_controller.md`

## Additional Resources

- [Grant Documentation](../docs/grant/README.md)
- [Grant Associations Guide](../docs/grant/associations.md)
- [Grant Security Features](../docs/grant/security-features.md)
- [Gemma Integration](../docs/gemma/grant-integration.md)
