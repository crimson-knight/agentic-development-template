# Documentation Integration Plan for Agentic Development Template

## Project Overview
Integrate Grant (ORM), Gemma (file attachments), and Asset Pipeline (frontend assets) into the agentic-development-template repository with complete documentation and pre-configured setup.

**Source Repositories:**
- Grant: https://github.com/crimson-knight/grant
- Gemma: https://github.com/crimson-knight/gemma
- Asset Pipeline: https://github.com/amberframework/asset_pipeline

**Target Repository:**
- Agentic Template: https://github.com/crimson-knight/agentic-development-template

---

## Phase 1: Repository Structure Setup

### 1.1 Create Documentation Structure
```
docs/
├── README.md (overview of all integrated shards)
├── grant/
│   ├── README.md (Grant ORM documentation)
│   ├── getting-started.md
│   ├── associations.md
│   ├── validations.md
│   ├── callbacks.md
│   ├── security-features.md
│   ├── advanced-features.md
│   └── examples.md
├── gemma/
│   ├── README.md (Gemma file attachments documentation)
│   ├── getting-started.md
│   ├── storage-backends.md
│   ├── grant-integration.md
│   ├── plugins.md
│   └── examples.md
├── asset_pipeline/
│   ├── README.md (Asset Pipeline documentation)
│   ├── getting-started.md
│   ├── javascript-modules.md
│   ├── import-maps.md
│   ├── cache-management.md
│   └── examples.md
└── integration/
    ├── full-stack-examples.md
    ├── best-practices.md
    └── troubleshooting.md
```

### 1.2 Create Help Documents for Agent
```
help/
├── grant/
│   ├── help_with_creating_models.md
│   ├── help_with_associations.md
│   ├── help_with_validations.md
│   ├── help_with_queries.md
│   └── help_with_migrations.md
├── gemma/
│   ├── help_with_file_uploads.md
│   ├── help_with_storage_config.md
│   └── help_with_grant_integration.md
└── asset_pipeline/
    ├── help_with_javascript_setup.md
    ├── help_with_import_maps.md
    └── help_with_cache_management.md
```

---

## Phase 2: Extract and Transform Documentation

### 2.1 Grant Documentation Extraction

**Source Content to Extract from Grant README:**

1. **Feature Comparison Table** - The comprehensive table showing Grant vs ActiveRecord feature parity
2. **Complete Model Examples** - User, Order, and Product model examples showing all features
3. **Query Methods** - All query interface methods and examples
4. **Association Types** - belongs_to, has_one, has_many, has_many :through, polymorphic
5. **Validation System** - All validators and custom validation examples
6. **Security Features**:
   - `encrypts` for encrypted attributes
   - `has_secure_token` for token generation
   - `include Grant::SignedId` for signed IDs
   - `include Grant::TokenFor` with `generates_token_for`
   - `normalizes` for data normalization
7. **Callback Lifecycle** - before_save, after_create, after_commit, etc.
8. **Transaction Examples** - transaction blocks, nested transactions, isolation levels
9. **Locking Examples** - optimistic and pessimistic locking with `with_lock`
10. **Enum Attributes** - `enum_attribute` with various configurations
11. **Serialized Columns** - `serializes` for JSON/YAML storage
12. **Attribute API** - Virtual attributes and custom types
13. **Dirty Tracking** - `changed?`, `attribute_was`, `saved_changes?`
14. **Scopes** - scope definitions and default_scope
15. **Aggregations** - Value objects with `aggregation`
16. **Sharding Support** - Link to SHARDING.md documentation
17. **Testing Setup** - Docker and local testing instructions

**Transform for Amber Template:**
- Add Amber-specific initialization code
- Include database.yml configuration examples
- Add migration file templates
- Create controller integration patterns
- Add view helper examples for form generation
- Include environment-specific configurations
- Add production deployment considerations

### 2.2 Gemma Documentation Extraction

**Source Content to Extract from Gemma README:**

1. **Basic Configuration**:
```crystal
Gemma.configure do |config|
  config.storages["cache"] = Storage::FileSystem.new("uploads", prefix: "cache")
  config.storages["store"] = Storage::FileSystem.new("uploads")
end
```

2. **Direct Upload Usage**:
```crystal
Gemma.upload(file, "store")
Gemma.upload(file, "store", metadata: { "filename" => "foo.bar" })
```

3. **Custom Uploader Classes**:
```crystal
class FileImport::AssetUploader < Gemma
  def generate_location(io : IO | UploadedFile, metadata, context, **options)
    name = super(io, metadata, **options)
    File.join("imports", context[:model].id.to_s, name)
  end
end
```

4. **Storage Backend Configuration**:
   - FileSystem storage
   - S3 storage with Awscr::S3::Client
   - S3-compatible services (DigitalOcean Spaces, Minio)
   - Upload options and public access configuration

5. **Grant ORM Integration** (PRIMARY FOCUS):
```crystal
require "gemma/grant"

class User < Grant::Base
  include Gemma::Grant::Attachable
  
  column avatar_data : JSON::Any?
  column documents_data : JSON::Any?
  
  # Single file attachment
  has_one_attached :avatar
  
  # Multiple file attachments
  has_many_attached :documents
end

# Usage
user.avatar = File.open("avatar.jpg")
user.documents = [File.open("doc1.pdf"), File.open("doc2.pdf")]
user.save

# Access
puts user.avatar_url
user.documents.each { |doc| puts doc.url }
```

6. **Validation Integration**:
```crystal
include Gemma::Grant::AttachmentValidators

validate_file_size_of :avatar, maximum: 5.megabytes
validate_content_type_of :avatar, accept: ["image/jpeg", "image/png"]
```

7. **Plugin System**:
   - **DetermineMimeType** - Get MIME type using File, Mime, or ContentType analyzers
   - **AddMetadata** - Extract and add custom metadata
   - **StoreDimensions** - Extract image dimensions using FastImage

8. **Other ORM Examples** (for reference):
   - Granite adapter example
   - Jennifer adapter example

**Transform for Amber Template:**
- Focus exclusively on Grant integration
- Add Amber file upload controller examples
- Include form helpers and view templates
- Add environment-specific storage configuration
- Create image processing workflow examples
- Add security best practices for file uploads
- Include CDN integration examples
- Add attachment validation patterns
- Create background processing examples

### 2.3 Asset Pipeline Documentation Extraction

**Source Content to Extract from Asset Pipeline README:**

1. **Basic Description**:
   - Handles JavaScript using ESM modules and import maps ✅ (Done v0.34)
   - CSS/SASS handling (TBD)
   - Image handling (TBD)

2. **Installation**:
```yaml
dependencies:
  asset_pipeline:
    github: amberframework/asset_pipeline
    version: 0.36.0
```

3. **FrontLoader Class Usage**:
```crystal
front_loader = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"]
) do |import_maps|
  import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])
  import_map.add_import("@hotwired/stimulus", "https://unpkg.com/@hotwired/stimulus/dist/stimulus.js")
  import_maps << import_map
end
```

4. **Automatic Cache Clearing** (v0.36.0 feature):
   - Enabled by default
   - Eliminates need for manual `FileUtils.rm_rf` calls
   - Cache cleared once per FrontLoader instance
   - Can be disabled with `clear_cache_upon_change: false`

5. **Configuration Options**:
   - `js_source_path` - Source directory for JavaScript files
   - `js_output_path` - Output directory for compiled JavaScript
   - `clear_cache_upon_change` - Automatic cache clearing toggle

6. **ImportMap Configuration**:
   - Create named import maps
   - Add external dependencies from CDNs
   - Support for multiple import maps

7. **When to Use Cache Clearing**:
   - ✅ During development (frequent file changes)
   - ✅ In CI/CD pipelines (fresh builds)
   - ✅ General usage (cleaner asset management)
   - ❌ When troubleshooting cache issues
   - ❌ When preserving cached files for debugging

**Transform for Amber Template:**
- Add Amber initializer integration
- Include view helper examples
- Add StimulusJS setup with controllers
- Create component-based architecture examples
- Add CSS/SASS integration roadmap
- Include production build configuration
- Add asset precompilation examples
- Create deployment strategies
- Add performance optimization tips
- Include debugging and troubleshooting guides

---

## Phase 3: Create Pre-Configured Template Files

### 3.1 Shard Configuration

**File:** `shard.yml`
```yaml
name: agentic-development-template
version: 0.1.0

authors:
  - Your Name <your.email@example.com>

crystal: 1.10.1

dependencies:
  amber:
    github: amberframework/amber
    version: ~> 1.4.0
  
  grant:
    github: crimson-knight/grant
    branch: main
  
  gemma:
    github: crimson-knight/gemma
    branch: master
  
  asset_pipeline:
    github: amberframework/asset_pipeline
    version: ~> 0.36.0
  
  # S3 support for Gemma in production
  awscr-s3:
    github: taylorfinnell/awscr-s3
    version: ~> 0.8.3

development_dependencies:
  # Add your development dependencies here

license: MIT
```

### 3.2 Database Configuration

**File:** `config/database.yml`
```yaml
development:
  adapter: postgresql
  database: <%= ENV["DB_NAME"] || "agentic_dev" %>
  host: <%= ENV["DB_HOST"] || "localhost" %>
  port: <%= ENV["DB_PORT"] || 5432 %>
  user: <%= ENV["DB_USER"] || "postgres" %>
  password: <%= ENV["DB_PASSWORD"] || "" %>
  pool_size: 25
  checkout_timeout: 5.0
  retry_attempts: 1
  retry_delay: 1.0

test:
  adapter: postgresql
  database: <%= ENV["DB_NAME"] || "agentic_test" %>
  host: <%= ENV["DB_HOST"] || "localhost" %>
  port: <%= ENV["DB_PORT"] || 5432 %>
  user: <%= ENV["DB_USER"] || "postgres" %>
  password: <%= ENV["DB_PASSWORD"] || "" %>
  pool_size: 25
  checkout_timeout: 5.0

production:
  adapter: postgresql
  url: <%= ENV["DATABASE_URL"] %>
  pool_size: 25
  checkout_timeout: 5.0
  retry_attempts: 2
  retry_delay: 1.0
```

### 3.3 Environment Variables Template

**File:** `.env.example`
```bash
# Database Configuration
DB_NAME=agentic_dev
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=

# Production Database (use connection string)
# DATABASE_URL=postgresql://user:password@host:port/database

# S3/Object Storage Configuration (for production file uploads)
S3_REGION=us-east-1
S3_KEY=your_access_key
S3_SECRET=your_secret_key
S3_BUCKET=your_bucket_name
# Optional: For S3-compatible services like DigitalOcean Spaces or Minio
S3_ENDPOINT=https://nyc3.digitaloceanspaces.com

# Application Configuration
SECRET_KEY_BASE=generate_with_amber_encrypt
AMBER_ENV=development
PORT=3000

# Optional: Encryption keys for Grant encrypted attributes
# ENCRYPTION_KEY=generate_a_secure_key_here
```

### 3.4 Grant Initializer

**File:** `config/initializers/grant.cr`
```crystal
require "grant"

# Configure Grant ORM for the application
Grant.configure do |config|
  # Set default connection
  config.default_connection = :pg
  
  # Configure PostgreSQL connection
  config.connections["pg"] = {
    adapter: "postgresql",
    database: ENV["DB_NAME"]? || "agentic_dev",
    host: ENV["DB_HOST"]? || "localhost",
    port: (ENV["DB_PORT"]? || "5432").to_i,
    user: ENV["DB_USER"]? || "postgres",
    password: ENV["DB_PASSWORD"]? || "",
    pool_size: 25,
    checkout_timeout: 5.0,
    retry_attempts: 1,
    retry_delay: 1.0
  }
  
  # Production configuration using DATABASE_URL
  if Amber.env.production? && ENV["DATABASE_URL"]?
    config.connections["pg"] = {
      url: ENV["DATABASE_URL"]
    }
  end
  
  # Optional: Configure read replica for scaling
  # config.connections["read_replica"] = {
  #   adapter: "postgresql",
  #   host: ENV["READ_REPLICA_HOST"]? || "localhost",
  #   database: ENV["DB_NAME"]? || "agentic_dev",
  #   # ... other settings
  # }
end

# Configure encryption for sensitive data
if encryption_key = ENV["ENCRYPTION_KEY"]?
  Grant::Encryption.primary_key = encryption_key
end

# Configure logging in development
if Amber.env.development?
  Grant.logger.level = Logger::DEBUG
end
```

### 3.5 Gemma Initializer

**File:** `config/initializers/gemma.cr`
```crystal
require "gemma"
require "gemma/grant"

# Configure Gemma file attachment system
Gemma.configure do |config|
  # Development and Test: Use filesystem storage
  if Amber.env.development? || Amber.env.test?
    # Cache storage for temporary uploads
    config.storages["cache"] = Gemma::Storage::FileSystem.new(
      "public/uploads/cache",
      prefix: "cache"
    )
    
    # Permanent storage
    config.storages["store"] = Gemma::Storage::FileSystem.new(
      "public/uploads"
    )
  end
  
  # Production: Use S3-compatible storage
  if Amber.env.production?
    require "awscr-s3"
    
    # Initialize S3 client
    client = Awscr::S3::Client.new(
      ENV["S3_REGION"],
      ENV["S3_KEY"],
      ENV["S3_SECRET"],
      endpoint: ENV["S3_ENDPOINT"]?
    )
    
    # Cache storage (temporary, not public)
    config.storages["cache"] = Gemma::Storage::S3.new(
      bucket: ENV["S3_BUCKET"],
      client: client,
      prefix: "cache",
      public: false
    )
    
    # Permanent storage (public access)
    config.storages["store"] = Gemma::Storage::S3.new(
      bucket: ENV["S3_BUCKET"],
      client: client,
      prefix: "uploads",
      public: true,
      upload_options: {
        "x-amz-acl" => "public-read"
      }
    )
  end
end

# Load Gemma plugins
class ApplicationUploader < Gemma
  # Determine MIME type from file contents
  load_plugin(
    Gemma::Plugins::DetermineMimeType,
    analyzer: Gemma::Plugins::DetermineMimeType::Tools::File
  )
  
  # Store image dimensions (requires fastimage shard)
  # load_plugin(
  #   Gemma::Plugins::StoreDimensions,
  #   analyzer: Gemma::Plugins::StoreDimensions::Tools::FastImage
  # )
  
  finalize_plugins!
end
```

### 3.6 Asset Pipeline Initializer

**File:** `config/initializers/asset_pipeline.cr`
```crystal
require "asset_pipeline"

module AssetConfig
  class_property front_loader : AssetPipeline::FrontLoader?
  
  def self.initialize_assets
    @@front_loader = AssetPipeline::FrontLoader.new(
      js_source_path: Path["src/javascript"],
      js_output_path: Path["public/javascript"],
      # Enable cache clearing in development, disable in production
      clear_cache_upon_change: Amber.env.development?
    ) do |import_maps|
      # Application JavaScript import map
      app_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])
      
      # Stimulus JS for interactive components
      app_map.add_import(
        "@hotwired/stimulus",
        "https://unpkg.com/@hotwired/stimulus@3.2.2/dist/stimulus.js"
      )
      
      # Turbo for seamless page updates (optional)
      app_map.add_import(
        "@hotwired/turbo",
        "https://unpkg.com/@hotwired/turbo@7.3.0/dist/turbo.es2017-esm.js"
      )
      
      # Add your custom JavaScript modules here
      # app_map.add_import("my-module", "/javascript/my_module.js")
      
      import_maps << app_map
    end
  end
  
  # Get import map HTML for views
  def self.import_map_html
    front_loader.try(&.import_maps.first?.try(&.to_html)) || ""
  end
end

# Initialize assets on application startup
AssetConfig.initialize_assets
```

### 3.7 Example Model with All Features

**File:** `src/models/user.cr`
```crystal
require "grant"
require "gemma/grant"

class User < Grant::Base
  include Gemma::Grant::Attachable
  include Gemma::Grant::AttachmentValidators
  
  connection pg
  table users
  
  # Primary key and basic columns
  column id : Int64, primary: true
  column email : String
  column first_name : String
  column last_name : String
  column bio : String?
  column active : Bool = true
  column login_count : Int32 = 0
  column last_login_at : Time?
  
  # File attachment columns (JSON storage)
  column avatar_data : JSON::Any?
  column resume_data : JSON::Any?
  
  # Security features
  has_secure_token :auth_token
  encrypts :ssn
  
  # Signed IDs for secure URLs
  include Grant::SignedId
  
  # Token generation for password resets
  include Grant::TokenFor
  generates_token_for :password_reset, expires_in: 15.minutes do
    # Use a field that changes when password changes
    updated_at.to_s
  end
  
  # Data normalization
  normalizes :email, &.downcase.strip
  normalizes :first_name, &.strip.titleize
  normalizes :last_name, &.strip.titleize
  
  # File attachments
  has_one_attached :avatar
  has_one_attached :resume
  
  # Enum attributes
  enum Role
    Guest
    Member
    Admin
  end
  enum_attribute role : Role = :member
  
  # Validations
  validates_presence_of :email, :first_name, :last_name
  validates_uniqueness_of :email
  validates_email :email
  validates_length_of :first_name, minimum: 2, maximum: 50
  validates_length_of :last_name, minimum: 2, maximum: 50
  validates_length_of :bio, maximum: 500, allow_blank: true
  
  # File attachment validations
  validate_file_size_of :avatar, maximum: 5.megabytes
  validate_content_type_of :avatar, accept: ["image/jpeg", "image/png", "image/webp"]
  validate_file_size_of :resume, maximum: 10.megabytes
  validate_content_type_of :resume, accept: ["application/pdf"]
  
  # Custom validation
  validate "cannot be admin if inactive" do |user|
    !(user.admin? && !user.active)
  end
  
  # Associations
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :nullify
  has_one :profile, dependent: :destroy
  
  # Scopes
  scope :active, ->{ where(active: true) }
  scope :admins, ->{ admin }
  scope :recent, ->{ where.gteq(:created_at, 7.days.ago) }
  default_scope ->{ where(active: true) }
  
  # Callbacks
  before_save :update_login_count
  after_create :send_welcome_email
  after_commit :notify_admin, on: :create
  
  # Timestamps
  timestamps
  
  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def avatar_url(size : String = "original")
    avatar.url if avatar
  end
  
  def can_edit?(resource)
    admin? || resource.user_id == id
  end
  
  private def update_login_count
    if last_login_at_changed?
      self.login_count += 1
    end
  end
  
  private def send_welcome_email
    # Email logic here
    puts "Sending welcome email to #{email}"
  end
  
  private def notify_admin
    # Admin notification logic
    puts "Notifying admin of new user: #{email}"
  end
end
```

### 3.8 Example Controller with File Uploads

**File:** `src/controllers/users_controller.cr`
```crystal
class UsersController < ApplicationController
  # GET /users
  def index
    users = User.all
    render "index.ecr"
  end
  
  # GET /users/:id
  def show
    if user = User.find_by(id: params[:id])
      render "show.ecr"
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end
  
  # GET /users/new
  def new
    user = User.new
    render "new.ecr"
  end
  
  # POST /users
  def create
    user = User.new(user_params)
    
    # Handle avatar upload
    if avatar = params.files["avatar"]?
      user.avatar = avatar.file
    end
    
    # Handle resume upload
    if resume = params.files["resume"]?
      user.resume = resume.file
    end
    
    if user.save
      redirect_to "/users/#{user.id}", flash: {"success" => "User created successfully!"}
    else
      flash.now["error"] = "Failed to create user: #{user.errors.full_messages.join(", ")}"
      render "new.ecr"
    end
  end
  
  # GET /users/:id/edit
  def edit
    if user = User.find_by(id: params[:id])
      render "edit.ecr"
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end
  
  # PATCH /users/:id
  def update
    if user = User.find_by(id: params[:id])
      # Update basic attributes
      user.assign_attributes(user_params)
      
      # Handle avatar upload
      if avatar = params.files["avatar"]?
        user.avatar = avatar.file
      end
      
      # Handle resume upload
      if resume = params.files["resume"]?
        user.resume = resume.file
      end
      
      if user.save
        redirect_to "/users/#{user.id}", flash: {"success" => "User updated successfully!"}
      else
        flash.now["error"] = "Failed to update user: #{user.errors.full_messages.join(", ")}"
        render "edit.ecr"
      end
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end
  
  # DELETE /users/:id
  def destroy
    if user = User.find_by(id: params[:id])
      user.destroy
      redirect_to "/users", flash: {"success" => "User deleted successfully!"}
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end
  
  private def user_params
    params.validation do
      required(:email) { |v| v.email? }
      required(:first_name) { |v| v.str? && !v.str.empty? }
      required(:last_name) { |v| v.str? && !v.str.empty? }
      optional(:bio) { |v| v.str? }
      optional(:role) { |v| v.str? }
    end
  end
end
```

### 3.9 Example View with File Upload Form

**File:** `src/views/users/new.ecr`
```html
<div class="container">
  <h1>Create New User</h1>
  
  <% if flash["error"]? %>
    <div class="alert alert-error">
      <%= flash["error"] %>
    </div>
  <% end %>
  
  <form action="/users" method="post" enctype="multipart/form-data" data-controller="user-form">
    <div class="form-group">
      <label for="email">Email</label>
      <input type="email" id="email" name="email" value="<%= user.email %>" required>
    </div>
    
    <div class="form-group">
      <label for="first_name">First Name</label>
      <input type="text" id="first_name" name="first_name" value="<%= user.first_name %>" required>
    </div>
    
    <div class="form-group">
      <label for="last_name">Last Name</label>
      <input type="text" id="last_name" name="last_name" value="<%= user.last_name %>" required>
    </div>
    
    <div class="form-group">
      <label for="bio">Bio</label>
      <textarea id="bio" name="bio" rows="4"><%= user.bio %></textarea>
    </div>
    
    <div class="form-group">
      <label for="avatar">Avatar Image</label>
      <input 
        type="file" 
        id="avatar" 
        name="avatar" 
        accept="image/jpeg,image/png,image/webp"
        data-user-form-target="avatarInput"
        data-action="change->user-form#previewAvatar">
      <small>Max 5MB. Accepted formats: JPEG, PNG, WebP</small>
      <div id="avatar-preview" data-user-form-target="avatarPreview"></div>
    </div>
    
    <div class="form-group">
      <label for="resume">Resume (PDF)</label>
      <input 
        type="file" 
        id="resume" 
        name="resume" 
        accept="application/pdf"
        data-user-form-target="resumeInput">
      <small>Max 10MB. PDF only</small>
    </div>
    
    <div class="form-actions">
      <button type="submit" class="btn btn-primary">Create User</button>
      <a href="/users" class="btn btn-secondary">Cancel</a>
    </div>
  </form>
</div>

<!-- Include import map for JavaScript -->
<%= AssetConfig.import_map_html %>
```

### 3.10 Example Stimulus Controller

**File:** `src/javascript/controllers/user_form_controller.js`
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["avatarInput", "avatarPreview", "resumeInput"]
  
  connect() {
    console.log("User form controller connected")
  }
  
  previewAvatar(event) {
    const file = event.target.files[0]
    
    if (file) {
      // Validate file size (5MB)
      if (file.size > 5 * 1024 * 1024) {
        alert("File size must be less than 5MB")
        this.avatarInputTarget.value = ""
        return
      }
      
      // Validate file type
      const allowedTypes = ["image/jpeg", "image/png", "image/webp"]
      if (!allowedTypes.includes(file.type)) {
        alert("Only JPEG, PNG, and WebP images are allowed")
        this.avatarInputTarget.value = ""
        return
      }
      
      // Create preview
      const reader = new FileReader()
      reader.onload = (e) => {
        this.avatarPreviewTarget.innerHTML = `
          <img src="${e.target.result}" alt="Avatar preview" style="max-width: 200px; margin-top: 10px;">
        `
      }
      reader.readAsDataURL(file)
    }
  }
  
  disconnect() {
    console.log("User form controller disconnected")
  }
}
```

### 3.11 Application Layout with Asset Pipeline

**File:** `src/views/layouts/application.ecr`
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><%= @page_title || "Agentic Development Template" %></title>
  
  <!-- Import Map for JavaScript modules -->
  <%= AssetConfig.import_map_html %>
  
  <!-- Application JavaScript -->
  <script type="module">
    import { Application } from "@hotwired/stimulus"
    
    // Import all controllers
    import UserFormController from "/javascript/controllers/user_form_controller.js"
    
    // Start Stimulus application
    window.Stimulus = Application.start()
    
    // Register controllers
    Stimulus.register("user-form", UserFormController)
  </script>
  
  <!-- Application CSS -->
  <link rel="stylesheet" href="/css/application.css">
</head>
<body>
  <header>
    <nav>
      <a href="/">Home</a>
      <a href="/users">Users</a>
    </nav>
  </header>
  
  <main>
    <%= content %>
  </main>
  
  <footer>
    <p>&copy; 2025 Agentic Development Template</p>
  </footer>
</body>
</html>
```

---

## Phase 4: Create AI Agent Instruction Files

### 4.1 Model Generation Instructions

**File:** `src/models/i_want_to_create_a_model.md`
```markdown
# Creating a Grant Model

This guide helps the AI agent create Grant ORM models following best practices.

## Prerequisites
- Grant ORM is configured in `config/initializers/grant.cr`
- Database connection is established
- Migrations are ready to run

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
    # Return true if valid, false if invalid
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
  
  # Enum provides helpful methods:
  # - order.pending?
  # - order.processing!
  # - Order.shipped.all
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
  before_create :set_defaults
  
  # After callbacks
  after_create :send_welcome_email
  after_save :update_search_index
  after_destroy :cleanup_data
  
  # Transaction callbacks
  after_commit :notify_external_service, on: :create
  after_rollback :log_failure
  
  timestamps
  
  private def normalize_email
    self.email = email.downcase.strip
  end
  
  private def increment_login_count
    self.login_count += 1
  end
  
  private def send_welcome_email
    # Email logic
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
  
  # Complex scopes
  scope :recent_active, ->{
    active.where.gteq(:created_at, 30.days.ago)
  }
  
  # Default scope (applied to all queries)
  default_scope ->{ where(active: true) }
  
  timestamps
end

# Usage:
# User.active.all
# User.admins.recent_active
# User.created_after(7.days.ago)
```

## Complete Example

```crystal
require "grant"
require "gemma/grant"

class User < Grant::Base
  include Gemma::Grant::Attachable
  include Gemma::Grant::AttachmentValidators
  include Grant::SignedId
  
  connection pg
  table users
  
  # Columns
  column id : Int64, primary: true
  column email : String
  column first_name : String
  column last_name : String
  column bio : String?
  column active : Bool = true
  column avatar_data : JSON::Any?
  
  # Security
  encrypts :ssn
  has_secure_token :auth_token
  
  # File attachments
  has_one_attached :avatar
  
  # Enums
  enum Role
    Member
    Admin
  end
  enum_attribute role : Role = :member
  
  # Associations
  has_many :posts, dependent: :destroy
  has_one :profile, dependent: :destroy
  
  # Validations
  validates_presence_of :email, :first_name, :last_name
  validates_uniqueness_of :email
  validates_email :email
  validates_length_of :bio, maximum: 500, allow_blank: true
  validate_file_size_of :avatar, maximum: 5.megabytes
  validate_content_type_of :avatar, accept: ["image/jpeg", "image/png"]
  
  # Callbacks
  before_save :normalize_email
  after_create :send_welcome_email
  
  # Scopes
  scope :active, ->{ where(active: true) }
  scope :admins, ->{ admin }
  
  # Data normalization
  normalizes :email, &.downcase.strip
  
  timestamps
  
  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end
  
  private def normalize_email
    self.email = email.downcase.strip
  end
  
  private def send_welcome_email
    # Email logic
  end
end
```

## Next Steps

1. Create a migration for your model: `amber generate migration CreateTableName`
2. Run the migration: `amber db migrate`
3. Test your model in the console: `amber exec`
4. Create a controller: See `src/controllers/i_want_to_create_a_controller.md`
```

### 4.2 Controller Generation Instructions

**File:** `src/controllers/i_want_to_create_a_controller.md`
```markdown
# Creating Controllers with Grant Models

This guide helps create controllers that work with Grant ORM models and Gemma file uploads.

## Basic CRUD Controller

```crystal
class UsersController < ApplicationController
  # GET /users
  def index
    users = User.all
    render "index.ecr"
  end
  
  # GET /users/:id
  def show
    if user = User.find_by(id: params[:id])
      render "show.ecr"
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end
  
  # GET /users/new
  def new
    user = User.new
    render "new.ecr"
  end
  
  # POST /users
  def create
    user = User.new(user_params)
    
    if user.save
      redirect_to "/users/#{user.id}", flash: {"success" => "User created!"}
    else
      flash.now["error"] = user.errors.full_messages.join(", ")
      render "new.ecr"
    end
  end
  
  # GET /users/:id/edit
  def edit
    if user = User.find_by(id: params[:id])
      render "edit.ecr"
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end
  
  # PATCH /users/:id
  def update
    if user = User.find_by(id: params[:id])
      if user.update(user_params)
        redirect_to "/users/#{user.id}", flash: {"success" => "User updated!"}
      else
        flash.now["error"] = user.errors.full_messages.join(", ")
        render "edit.ecr"
      end
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end
  
  # DELETE /users/:id
  def destroy
    if user = User.find_by(id: params[:id])
      user.destroy
      redirect_to "/users", flash: {"success" => "User deleted!"}
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end
  
  private def user_params
    params.validation do
      required(:email) { |v| v.email? }
      required(:first_name) { |v| v.str? && !v.str.empty? }
      required(:last_name) { |v| v.str? && !v.str.empty? }
      optional(:bio) { |v| v.str? }
    end
  end
end
```

## Controller with File Uploads

```crystal
class UsersController < ApplicationController
  # POST /users
  def create
    user = User.new(user_params)
    
    # Handle single file upload
    if avatar = params.files["avatar"]?
      user.avatar = avatar.file
    end
    
    # Handle multiple file uploads
    if documents = params.files.get_all("documents")
      user.documents = documents.map(&.file)
    end
    
    if user.save
      redirect_to "/users/#{user.id}", flash: {"success" => "User created!"}
    else
      flash.now["error"] = user.errors.full_messages.join(", ")
      render "new.ecr"
    end
  end
  
  # PATCH /users/:id
  def update
    if user = User.find_by(id: params[:id])
      user.assign_attributes(user_params)
      
      # Handle file upload
      if avatar = params.files["avatar"]?
        user.avatar = avatar.file
      end
      
      # Remove file if checkbox is checked
      if params["remove_avatar"]? == "1"
        user.avatar = nil
      end
      
      if user.save
        redirect_to "/users/#{user.id}", flash: {"success" => "User updated!"}
      else
        flash.now["error"] = user.errors.full_messages.join(", ")
        render "edit.ecr"
      end
    else
      redirect_to "/users", flash: {"error" => "User not found"}
    end
  end
  
  private def user_params
    params.validation do
      required(:email) { |v| v.email? }
      required(:first_name) { |v| v.str? && !v.str.empty? }
      required(:last_name) { |v| v.str? && !v.str.empty? }
      optional(:bio) { |v| v.str? }
    end
  end
end
```

## Controller with Query Scopes

```crystal
class UsersController < ApplicationController
  # GET /users?status=active&role=admin
  def index
    users = User.all
    
    # Apply scopes based on params
    users = users.active if params["status"]? == "active"
    users = users.admins if params["role"]? == "admin"
    users = users.created_after(7.days.ago) if params["recent"]?
    
    # Pagination
    page = (params["page"]? || "1").to_i
    per_page = 20
    users = users.limit(per_page).offset((page - 1) * per_page)
    
    render "index.ecr"
  end
end
```

## API Controller with JSON Responses

```crystal
class Api::UsersController < ApplicationController
  # GET /api/users
  def index
    users = User.all.limit(100)
    
    render json: {
      users: users.map { |u| user_json(u) }
    }
  end
  
  # GET /api/users/:id
  def show
    if user = User.find_by(id: params[:id])
      render json: user_json(user)
    else
      render json: {error: "User not found"}, status: 404
    end
  end
  
  # POST /api/users
  def create
    user = User.new(user_params)
    
    if user.save
      render json: user_json(user), status: 201
    else
      render json: {errors: user.errors.messages}, status: 422
    end
  end
  
  private def user_json(user)
    {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      avatar_url: user.avatar_url,
      created_at: user.created_at
    }
  end
  
  private def user_params
    params.validation do
      required(:email) { |v| v.email? }
      required(:first_name) { |v| v.str? && !v.str.empty? }
      required(:last_name) { |v| v.str? && !v.str.empty? }
    end
  end
end
```

## Controller with Transactions

```crystal
class OrdersController < ApplicationController
  # POST /orders
  def create
    Grant::Base.transaction do
      # Create order
      order = Order.new(order_params)
      order.user_id = current_user.id
      order.save!
      
      # Create line items
      params["items"].each do |item_data|
        line_item = LineItem.new(
          order_id: order.id,
          product_id: item_data["product_id"],
          quantity: item_data["quantity"]
        )
        line_item.save!
      end
      
      # Update inventory
      order.line_items.each do |item|
        product = Product.find(item.product_id)
        product.decrement!(:inventory_count, item.quantity)
      end
      
      redirect_to "/orders/#{order.id}", flash: {"success" => "Order created!"}
    end
  rescue ex
    flash["error"] = "Failed to create order: #{ex.message}"
    render "new.ecr"
  end
end
```

## Routes Configuration

```crystal
# config/routes.cr
Amber::Server.configure do
  routes :web do
    # RESTful routes
    resources "/users", UsersController
    
    # Custom routes
    get "/users/:id/profile", UsersController, :profile
    post "/users/:id/avatar", UsersController, :update_avatar
    delete "/users/:id/avatar", UsersController, :remove_avatar
  end
  
  routes :api do
    resources "/users", Api::UsersController, only: [:index, :show, :create]
  end
end
```

## Next Steps

1. Create views: See `src/views/i_want_to_create_views.md`
2. Add JavaScript interactivity: See `src/javascript/i_want_to_add_javascript.md`
3. Test your controller: See `spec/controllers/`
```

### 4.3 File Upload Instructions

**File:** `help/gemma/help_with_file_uploads.md`
```markdown
# Working with File Uploads using Gemma

This guide covers everything about handling file uploads with Gemma and Grant.

## Basic Setup

Gemma is already configured in `config/initializers/gemma.cr` with:
- Filesystem storage for development/test
- S3 storage for production

## Adding File Attachments to Models

### Single File Attachment

```crystal
require "grant"
require "gemma/grant"

class User < Grant::Base
  include Gemma::Grant::Attachable
  
  connection pg
  table users
  
  column id : Int64, primary: true
  column name : String
  column avatar_data : JSON::Any?
  
  has_one_attached :avatar
  
  timestamps
end
```

### Multiple File Attachments

```crystal
class Post < Grant::Base
  include Gemma::Grant::Attachable
  
  connection pg
  table posts
  
  column id : Int64, primary: true
  column title : String
  column images_data : JSON::Any?
  
  has_many_attached :images
  
  timestamps
end
```

## File Validations

```crystal
class User < Grant::Base
  include Gemma::Grant::Attachable
  include Gemma::Grant::AttachmentValidators
  
  column avatar_data : JSON::Any?
  
  has_one_attached :avatar
  
  # File size validation
  validate_file_size_of :avatar, maximum: 5.megabytes
  validate_file_size_of :avatar, minimum: 100.kilobytes, maximum: 5.megabytes
  
  # Content type validation
  validate_content_type_of :avatar, accept: ["image/jpeg", "image/png", "image/webp"]
  validate_content_type_of :avatar, reject: ["image/gif"]
  
  # Dimension validation (requires fastimage shard)
  # validate_dimensions_of :avatar, 
  #   min_width: 100, 
  #   max_width: 2000,
  #   min_height: 100,
  #   max_height: 2000
end
```

## Controller Usage

### Handling Single File Upload

```crystal
class UsersController < ApplicationController
  def create
    user = User.new(user_params)
    
    # Attach file from form
    if avatar = params.files["avatar"]?
      user.avatar = avatar.file
    end
    
    if user.save
      redirect_to "/users/#{user.id}"
    else
      render "new.ecr"
    end
  end
  
  def update
    if user = User.find_by(id: params[:id])
      user.assign_attributes(user_params)
      
      # Update avatar if provided
      if avatar = params.files["avatar"]?
        user.avatar = avatar.file
      end
      
      # Remove avatar if requested
      if params["remove_avatar"]? == "1"
        user.avatar.destroy if user.avatar
        user.avatar_data = nil
      end
      
      user.save
      redirect_to "/users/#{user.id}"
    end
  end
end
```

### Handling Multiple File Uploads

```crystal
class PostsController < ApplicationController
  def create
    post = Post.new(post_params)
    
    # Attach multiple files
    if images = params.files.get_all("images")
      post.images = images.map(&.file)
    end
    
    post.save
    redirect_to "/posts/#{post.id}"
  end
  
  def add_image
    if post = Post.find_by(id: params[:id])
      if image = params.files["image"]?
        # Append to existing attachments
        post.images << image.file
        post.save
      end
      redirect_to "/posts/#{post.id}"
    end
  end
end
```

## View Templates

### Single File Upload Form

```html
<form action="/users" method="post" enctype="multipart/form-data">
  <div>
    <label for="avatar">Avatar</label>
    <input type="file" id="avatar" name="avatar" accept="image/*">
    <small>Max 5MB. JPEG, PNG, or WebP</small>
  </div>
  
  <button type="submit">Upload</button>
</form>
```

### Multiple File Upload Form

```html
<form action="/posts" method="post" enctype="multipart/form-data">
  <div>
    <label for="images">Images</label>
    <input type="file" id="images" name="images" multiple accept="image/*">
    <small>Select multiple images (max 5MB each)</small>
  </div>
  
  <button type="submit">Upload</button>
</form>
```

### Edit Form with Current File Display

```html
<form action="/users/<%= user.id %>" method="post" enctype="multipart/form-data">
  <input type="hidden" name="_method" value="PATCH">
  
  <% if user.avatar %>
    <div>
      <p>Current Avatar:</p>
      <img src="<%= user.avatar.url %>" alt="Avatar" width="200">
      
      <label>
        <input type="checkbox" name="remove_avatar" value="1">
        Remove avatar
      </label>
    </div>
  <% end %>
  
  <div>
    <label for="avatar">New Avatar</label>
    <input type="file" id="avatar" name="avatar" accept="image/*">
  </div>
  
  <button type="submit">Update</button>
</form>
```

## Accessing File URLs

```crystal
# In controller or view
user = User.find(1)

# Get file URL
user.avatar.url
# => "/uploads/users/1/avatar/abc123.jpg"

# Check if file exists
user.avatar.present?
user.avatar.nil?

# Get metadata
user.avatar.filename
user.avatar.size
user.avatar.content_type

# Multiple attachments
user.documents.each do |doc|
  puts doc.url
  puts doc.filename
end
```

## Direct File Access

```crystal
# Download file
user.avatar.download do |file|
  # Process file
end

# Get IO for streaming
user.avatar.open do |io|
  # Stream file
end

# Get file data
data = user.avatar.read
```

## Custom Uploaders

```crystal
class AvatarUploader < Gemma
  # Custom file location
  def generate_location(io, metadata, context, **options)
    name = super(io, metadata, **options)
    user_id = context[:model].id
    File.join("avatars", user_id.to_s, name)
  end
  
  # Process after upload
  def process(io, context)
    # Resize, optimize, etc.
    io
  end
end

# Use in controller
class UsersController < ApplicationController
  def create
    user = User.new(user_params)
    
    if avatar = params.files["avatar"]?
      uploaded = AvatarUploader.upload(
        avatar.file,
        "store",
        context: { model: user }
      )
      user.avatar_data = JSON.parse(uploaded.to_json)
    end
    
    user.save
  end
end
```

## Storage Configuration

### Development (Filesystem)

Files are stored in `public/uploads/`

### Production (S3)

Configured in `config/initializers/gemma.cr`:

```crystal
if Amber.env.production?
  require "awscr-s3"
  
  client = Awscr::S3::Client.new(
    ENV["S3_REGION"],
    ENV["S3_KEY"],
    ENV["S3_SECRET"],
    endpoint: ENV["S3_ENDPOINT"]?
  )
  
  config.storages["store"] = Gemma::Storage::S3.new(
    bucket: ENV["S3_BUCKET"],
    client: client,
    public: true
  )
end
```

Environment variables needed:
- `S3_REGION` - AWS region (e.g., "us-east-1")
- `S3_KEY` - Access key
- `S3_SECRET` - Secret key
- `S3_BUCKET` - Bucket name
- `S3_ENDPOINT` (optional) - For S3-compatible services

## Common Patterns

### Image Variants (Thumbnails)

```crystal
# This feature is being developed
# For now, use image processing libraries directly
```

### Background Processing

```crystal
# Process files in background job
class ProcessAvatarJob
  def perform(user_id)
    user = User.find(user_id)
    
    if user.avatar
      # Process image
      # Create thumbnails
      # etc.
    end
  end
end

# In controller
def create
  user = User.new(user_params)
  
  if avatar = params.files["avatar"]?
    user.avatar = avatar.file
  end
  
  if user.save
    ProcessAvatarJob.new.perform(user.id)
    redirect_to "/users/#{user.id}"
  end
end
```

### Direct Uploads (S3)

```crystal
# Generate presigned URL for direct upload to S3
# This requires additional configuration
```

## Troubleshooting

### File not saving
- Check that column exists: `avatar_data : JSON::Any?`
- Check that `Gemma::Grant::Attachable` is included
- Check file validations
- Check storage configuration

### File size too large
- Check web server limits (Nginx, Apache)
- Check Amber max request size
- Increase validation limits

### S3 upload fails
- Check credentials in .env
- Check bucket permissions
- Check CORS configuration
- Check endpoint URL for S3-compatible services

## Migration Example

```crystal
# db/migrations/20250101_add_avatar_to_users.sql
ALTER TABLE users ADD COLUMN avatar_data JSONB;
```

## Security Best Practices

1. Always validate file types
2. Limit file sizes
3. Scan files for malware in production
4. Use signed URLs for private files
5. Store files outside web root in production
6. Validate file extensions match content type
7. Use Content-Disposition headers
8. Implement rate limiting for uploads

## Testing

```crystal
# spec/models/user_spec.cr
describe User do
  describe "avatar attachment" do
    it "attaches avatar" do
      user = User.new(name: "Test")
      file = File.open("spec/fixtures/avatar.jpg")
      
      user.avatar = file
      user.save
      
      user.avatar.should_not be_nil
      user.avatar.filename.should eq("avatar.jpg")
    end
    
    it "validates file size" do
      user = User.new(name: "Test")
      large_file = File.open("spec/fixtures/large.jpg") # > 5MB
      
      user.avatar = large_file
      user.save
      
      user.errors.messages["avatar"]?.should_not be_nil
    end
  end
end
```
```

### 4.4 JavaScript Module Instructions

**File:** `help/asset_pipeline/help_with_javascript_setup.md`
```markdown
# Working with JavaScript using Asset Pipeline

This guide covers creating JavaScript modules and Stimulus controllers.

## Asset Pipeline Setup

Asset Pipeline is configured in `config/initializers/asset_pipeline.cr`.

Key concepts:
- **Import Maps**: Define where JavaScript modules are loaded from
- **ESM Modules**: Use modern ES module syntax
- **Automatic Cache Clearing**: Cache is cleared automatically in development

## Creating Stimulus Controllers

Stimulus controllers provide interactivity without writing a lot of JavaScript.

### Basic Controller Structure

```javascript
// src/javascript/controllers/hello_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Define targets (DOM elements this controller manages)
  static targets = ["name", "output"]
  
  // Define values (data attributes)
  static values = {
    name: String,
    count: { type: Number, default: 0 }
  }
  
  // Called when controller connects to DOM
  connect() {
    console.log("Hello controller connected!")
  }
  
  // Action methods (called from HTML)
  greet() {
    const name = this.nameTarget.value
    this.outputTarget.textContent = `Hello, ${name}!`
    this.countValue++
  }
  
  // Called when controller disconnects from DOM
  disconnect() {
    console.log("Hello controller disconnected!")
  }
}
```

### Using Controller in HTML

```html
<div data-controller="hello">
  <input 
    type="text" 
    data-hello-target="name"
    placeholder="Enter your name">
  
  <button data-action="click->hello#greet">
    Greet
  </button>
  
  <div data-hello-target="output"></div>
</div>
```

## Real-World Examples

### Form Validation Controller

```javascript
// src/javascript/controllers/form_validation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "password", "error"]
  
  connect() {
    this.element.addEventListener("submit", this.validate.bind(this))
  }
  
  validate(event) {
    this.clearErrors()
    
    const email = this.emailTarget.value
    const password = this.passwordTarget.value
    
    let isValid = true
    
    // Email validation
    if (!this.isValidEmail(email)) {
      this.showError("Please enter a valid email address")
      isValid = false
    }
    
    // Password validation
    if (password.length < 8) {
      this.showError("Password must be at least 8 characters")
      isValid = false
    }
    
    if (!isValid) {
      event.preventDefault()
    }
  }
  
  isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
  }
  
  showError(message) {
    const errorDiv = document.createElement("div")
    errorDiv.className = "error-message"
    errorDiv.textContent = message
    this.errorTarget.appendChild(errorDiv)
  }
  
  clearErrors() {
    this.errorTarget.innerHTML = ""
  }
}
```

### File Upload Preview Controller

```javascript
// src/javascript/controllers/file_preview_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "filename"]
  static values = {
    maxSize: { type: Number, default: 5 * 1024 * 1024 }, // 5MB
    acceptedTypes: { type: Array, default: ["image/jpeg", "image/png", "image/webp"] }
  }
  
  preview(event) {
    const file = event.target.files[0]
    
    if (!file) {
      this.clearPreview()
      return
    }
    
    // Validate file
    if (!this.validate(file)) {
      this.inputTarget.value = ""
      return
    }
    
    // Show filename
    if (this.hasFilenameTarget) {
      this.filenameTarget.textContent = file.name
    }
    
    // Preview image
    if (file.type.startsWith("image/")) {
      this.previewImage(file)
    }
  }
  
  validate(file) {
    // Check file size
    if (file.size > this.maxSizeValue) {
      alert(`File size must be less than ${this.maxSizeValue / 1024 / 1024}MB`)
      return false
    }
    
    // Check file type
    if (!this.acceptedTypesValue.includes(file.type)) {
      alert(`Only ${this.acceptedTypesValue.join(", ")} files are allowed`)
      return false
    }
    
    return true
  }
  
  previewImage(file) {
    const reader = new FileReader()
    
    reader.onload = (e) => {
      if (this.hasPreviewTarget) {
        this.previewTarget.innerHTML = `
          <img src="${e.target.result}" alt="Preview" style="max-width: 100%; max-height: 300px;">
        `
      }
    }
    
    reader.readAsDataURL(file)
  }
  
  clearPreview() {
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = ""
    }
    if (this.hasFilenameTarget) {
      this.filenameTarget.textContent = ""
    }
  }
}
```

### AJAX Form Controller

```javascript
// src/javascript/controllers/ajax_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "output", "submit"]
  static values = {
    url: String,
    method: { type: String, default: "POST" }
  }
  
  async submit(event) {
    event.preventDefault()
    
    this.setLoading(true)
    
    try {
      const formData = new FormData(this.formTarget)
      
      const response = await fetch(this.urlValue, {
        method: this.methodValue,
        body: formData,
        headers: {
          "X-Requested-With": "XMLHttpRequest"
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.handleSuccess(data)
      } else {
        this.handleError(response)
      }
    } catch (error) {
      this.handleError(error)
    } finally {
      this.setLoading(false)
    }
  }
  
  setLoading(loading) {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = loading
      this.submitTarget.textContent = loading ? "Loading..." : "Submit"
    }
  }
  
  handleSuccess(data) {
    if (this.hasOutputTarget) {
      this.outputTarget.innerHTML = `
        <div class="success-message">${data.message}</div>
      `
    }
    
    // Reset form
    this.formTarget.reset()
  }
  
  handleError(error) {
    if (this.hasOutputTarget) {
      this.outputTarget.innerHTML = `
        <div class="error-message">An error occurred. Please try again.</div>
      `
    }
    
    console.error("Form submission error:", error)
  }
}
```

## Registering Controllers

Controllers must be registered in the application layout:

```html
<!-- src/views/layouts/application.ecr -->
<!DOCTYPE html>
<html>
<head>
  <%= AssetConfig.import_map_html %>
  
  <script type="module">
    import { Application } from "@hotwired/stimulus"
    
    // Import controllers
    import HelloController from "/javascript/controllers/hello_controller.js"
    import FormValidationController from "/javascript/controllers/form_validation_controller.js"
    import FilePreviewController from "/javascript/controllers/file_preview_controller.js"
    import AjaxFormController from "/javascript/controllers/ajax_form_controller.js"
    
    // Start Stimulus
    window.Stimulus = Application.start()
    
    // Register controllers
    Stimulus.register("hello", HelloController)
    Stimulus.register("form-validation", FormValidationController)
    Stimulus.register("file-preview", FilePreviewController)
    Stimulus.register("ajax-form", AjaxFormController)
  </script>
</head>
<body>
  <%= content %>
</body>
</html>
```

## Creating Custom Modules

### Utility Module

```javascript
// src/javascript/utils/api.js
export class API {
  static async get(url) {
    const response = await fetch(url, {
      headers: {
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }
    
    return await response.json()
  }
  
  static async post(url, data) {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Requested-With": "XMLHttpRequest"
      },
      body: JSON.stringify(data)
    })
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }
    
    return await response.json()
  }
}
```

### Using Utility Module

```javascript
// src/javascript/controllers/data_controller.js
import { Controller } from "@hotwired/stimulus"
import { API } from "../utils/api.js"

export default class extends Controller {
  async loadData() {
    try {
      const data = await API.get("/api/users")
      this.displayData(data)
    } catch (error) {
      console.error("Failed to load data:", error)
    }
  }
  
  displayData(data) {
    // Display logic
  }
}
```

## Adding External Libraries

Add libraries to the import map in `config/initializers/asset_pipeline.cr`:

```crystal
app_map.add_import(
  "library-name",
  "https://unpkg.com/library-name@version/dist/library.js"
)
```

Then import in your controllers:

```javascript
import LibraryName from "library-name"
```

## Debugging

### Enable Stimulus Debugging

```javascript
// In application layout
window.Stimulus = Application.start()
Stimulus.debug = true // Enable debug logging
```

### Common Issues

1. **Controller not connecting**
   - Check `data-controller` attribute matches registration name
   - Check controller is imported and registered
   - Check console for errors

2. **Action not firing**
   - Check `data-action` syntax: `event->controller#method`
   - Check method exists in controller
   - Check element is within controller scope

3. **Target not found**
   - Check `data-{controller}-target` attribute
   - Check target name is in `static targets` array
   - Check element is within controller scope

## Best Practices

1. Keep controllers small and focused
2. Use Stimulus values for configuration
3. Avoid direct DOM manipulation outside targets
4. Use semantic HTML with progressive enhancement
5. Handle errors gracefully
6. Clean up in disconnect()
7. Use CSS classes for styling, not inline styles
8. Test controllers with real user interactions

## Production Optimization

Asset Pipeline automatically handles:
- Cache management
- Module bundling
- Import map generation

For production deployment:
- Files are served from `public/javascript/`
- Import maps are generated automatically
- CDN resources are loaded from configured URLs
```

---

## Phase 5: Integration Implementation Checklist

This checklist should be followed in order by Claude Code.

### Step 1: Create Directory Structure
- [ ] Create `docs/` directory with subdirectories
  - [ ] `docs/grant/`
  - [ ] `docs/gemma/`
  - [ ] `docs/asset_pipeline/`
  - [ ] `docs/integration/`
- [ ] Create `help/` directory with subdirectories
  - [ ] `help/grant/`
  - [ ] `help/gemma/`
  - [ ] `help/asset_pipeline/`

### Step 2: Update Configuration Files
- [ ] Update `shard.yml` with all dependencies
- [ ] Create/update `config/database.yml`
- [ ] Create `.env.example` file
- [ ] Add `.env` to `.gitignore`

### Step 3: Create Initializers
- [ ] Create `config/initializers/grant.cr`
- [ ] Create `config/initializers/gemma.cr`
- [ ] Create `config/initializers/asset_pipeline.cr`
- [ ] Ensure initializers are loaded in application

### Step 4: Create Documentation Files
- [ ] Create `docs/README.md` (overview)
- [ ] Create all Grant documentation files
- [ ] Create all Gemma documentation files
- [ ] Create all Asset Pipeline documentation files
- [ ] Create integration documentation

### Step 5: Create Help Files for AI Agent
- [ ] Create all Grant help files
- [ ] Create all Gemma help files
- [ ] Create all Asset Pipeline help files

### Step 6: Create Example Files
- [ ] Create `src/models/user.cr` (example model)
- [ ] Create `src/controllers/users_controller.cr` (example controller)
- [ ] Create views for user management
- [ ] Create Stimulus controllers examples
- [ ] Update application layout with Asset Pipeline

### Step 7: Create Migration Templates
- [ ] Create example migration files
- [ ] Document migration workflow
- [ ] Create migration generator instructions

### Step 8: Create Testing Examples
- [ ] Create model spec examples
- [ ] Create controller spec examples
- [ ] Create file upload spec examples
- [ ] Document testing best practices

### Step 9: Update Main README
- [ ] Add overview of integrated shards
- [ ] Add quick start guide
- [ ] Add links to detailed documentation
- [ ] Add troubleshooting section

### Step 10: Final Verification
- [ ] Verify all files are created
- [ ] Check all links in documentation
- [ ] Test example code for syntax errors
- [ ] Review consistency across all documentation

---

## Phase 6: Documentation Content Requirements

Each documentation section should include:

### Grant Documentation (`docs/grant/`)
1. **README.md**
   - Feature comparison table
   - Quick start guide
   - Links to detailed docs

2. **getting-started.md**
   - Installation
   - Configuration
   - Creating first model
   - Running migrations

3. **associations.md**
   - All association types with examples
   - Association options
   - Through associations
   - Polymorphic associations

4. **validations.md**
   - Built-in validators
   - Custom validators
   - Validation contexts
   - Error handling

5. **callbacks.md**
   - Lifecycle callbacks
   - Transaction callbacks
   - Callback examples

6. **security-features.md**
   - Encrypted attributes
   - Secure tokens
   - Signed IDs
   - Token generation
   - Data normalization

7. **advanced-features.md**
   - Enums
   - Serialization
   - Value objects
   - Dirty tracking
   - Attribute API
   - Scopes
   - Transactions
   - Locking
   - Sharding

8. **examples.md**
   - Complete User model
   - Complete Order model
   - Complete Product model

### Gemma Documentation (`docs/gemma/`)
1. **README.md**
   - Overview
   - Quick start
   - Feature list

2. **getting-started.md**
   - Installation
   - Configuration
   - First file upload

3. **storage-backends.md**
   - FileSystem storage
   - S3 storage
   - Configuration examples

4. **grant-integration.md**
   - has_one_attached
   - has_many_attached
   - Validations
   - Complete examples

5. **plugins.md**
   - DetermineMimeType
   - AddMetadata
   - StoreDimensions
   - Creating custom plugins

6. **examples.md**
   - User with avatar
   - Post with images
   - Document management

### Asset Pipeline Documentation (`docs/asset_pipeline/`)
1. **README.md**
   - Overview
   - Features
   - Quick start

2. **getting-started.md**
   - Installation
   - Configuration
   - First module

3. **javascript-modules.md**
   - ESM syntax
   - Creating modules
   - Importing modules

4. **import-maps.md**
   - What are import maps
   - Configuration
   - Adding external libraries

5. **cache-management.md**
   - Automatic cache clearing
   - When to disable
   - Manual cache management

6. **examples.md**
   - Stimulus controllers
   - Utility modules
   - Third-party integration

---

## Implementation Notes for Claude Code

### Priority Order
1. **High Priority** (Do First)
   - Directory structure
   - Configuration files
   - Initializers
   - Core documentation (README files)

2. **Medium Priority** (Do Second)
   - Example models and controllers
   - Detailed documentation
   - Help files for AI agent

3. **Low Priority** (Do Last)
   - Advanced examples
   - Testing examples
   - Troubleshooting guides

### Code Style Guidelines
- Follow Crystal style guide
- Use consistent indentation (2 spaces)
- Add comments for complex logic
- Use descriptive variable names
- Follow Amber conventions

### Documentation Style Guidelines
- Use clear, concise language
- Include code examples for every concept
- Provide both simple and complex examples
- Add troubleshooting sections
- Use consistent formatting
- Include table of contents for long documents

### Testing Requirements
- All example code should be valid Crystal syntax
- Models should include proper types
- Controllers should handle errors
- Views should escape user input
- JavaScript should use modern ES6+ syntax

---

## Success Criteria

The integration is complete when:
- [ ] All documentation files are created and complete
- [ ] All example code is syntactically correct
- [ ] All help files for AI agent are comprehensive
- [ ] Configuration files are properly set up
- [ ] Directory structure matches specification
- [ ] Main README links to all documentation
- [ ] Examples demonstrate all major features
- [ ] Troubleshooting guides cover common issues

---

## Additional Resources

Reference the following for implementation:
- Grant README: https://github.com/crimson-knight/grant
- Gemma README: https://github.com/crimson-knight/gemma
- Asset Pipeline README: https://github.com/amberframework/asset_pipeline
- Crystal language docs: https://crystal-lang.org/docs
- Amber framework docs: https://docs.amberframework.org

---

## Questions to Ask if Unclear

1. Should we create example specs for testing?
2. Should we include CI/CD configuration?
3. Should we add Docker configuration for development?
4. Should we create database seed files?
5. Should we add API documentation examples?
6. Should we include deployment guides?

---

## End of Plan

This plan should be executed sequentially. Each phase builds on the previous one. Claude Code should create a branch, implement this plan, and submit a PR for review.