# AgentC Application Template - Technical Guide

This document provides comprehensive technical information about the libraries, architecture, and patterns used in this Crystal/Amber application template.

## 📚 Technology Stack

### Core Framework

**Amber Framework** - Ruby on Rails-inspired web framework for Crystal
- **Version**: Latest from `crimson-knight/amber` (master branch)
- **Purpose**: Web application framework providing MVC architecture, routing, controllers, middleware
- **Location**: `lib/amber/`
- **Documentation**: `lib/amber/CLAUDE.md`

**Crystal Language**
- **Version**: 1.14.0+
- **Purpose**: Statically-typed, compiled language with Ruby-like syntax
- **Performance**: Near C/Rust performance with developer-friendly syntax

### Database & ORM

**Grant ORM** - Active Record-style ORM for Crystal
- **Repository**: `crimson-knight/grant` (main branch)
- **Purpose**: Database abstraction, models, queries, validations, associations
- **Status**: ✅ **Fully Migrated** - Replaced Granite ORM
- **Location**: `lib/grant/`
- **Documentation**: `lib/grant/CLAUDE.md`
- **Key Features**:
  - Active Record pattern
  - Type-safe queries
  - Associations (has_many, belongs_to, has_one, many_to_many)
  - Validations
  - Callbacks
  - Connection management (writer/reader separation)
  - Multi-database support
  - Encryption support
  - Optimistic locking

**PostgreSQL** - Primary database
- **Version**: 14+
- **Purpose**: Relational data storage
- **Configuration**: `config/database.cr` (ENV-based, no YAML processing)

**Micrate** - Database migrations
- **Repository**: `amberframework/micrate` (master branch)
- **Purpose**: Database schema migrations
- **Location**: `db/migrations/`

### View Layer

**AssetPipeline** - Component-based view system
- **Repository**: `amberframework/asset_pipeline` (main branch)
- **Purpose**: Type-safe, object-oriented view components replacing string templates
- **Location**: `lib/asset_pipeline/`
- **Skills**:
  - `.claude/skills/asset-pipeline-components.md` - How to build components
  - `.claude/skills/asset-pipeline-element-reference.md` - Complete element/attribute reference
- **Architecture**:
  - **Pages**: Full views (HomePageComponent, DashboardComponent)
  - **Components**: Reusable UI units (ButtonComponent, CardComponent)
  - **Elements**: HTML5 building blocks (87 typed element classes)
- **Performance**: Automatic caching for stateless components (500x improvement)

**Component Categories**:
- `src/views/components/shared/` - Reusable UI components
- `src/views/components/layouts/` - Page structure components
- `src/views/components/pages/` - Full page views
- `src/views/components/forms/` - Form components with validation

### Email

**Quartz Mailer** - Email delivery
- **Repository**: `amberframework/quartz-mailer`
- **Version**: ~> 0.8.0
- **Purpose**: Sending emails (SMTP, component-based templates)
- **Component-based**: Uses AssetPipeline components for email templates
- **Example**: `src/views/components/layouts/mailer_layout.cr`

### Asset Management

**Asset Pipeline** (also handles static assets)
- **Purpose**: JavaScript/CSS bundling, import maps, Stimulus integration
- **Features**:
  - Import maps for JavaScript modules
  - Stimulus framework support
  - Dependency analysis
  - Framework registry (extensible)

**Gemma** - File attachments and storage
- **Repository**: `crimson-knight/gemma` (master branch)
- **Purpose**: File uploads, storage, S3 integration
- **S3 Support**: Uses `awscr-s3` (transitive dependency)

### Protocol & Communication

**MCProtocol** - Model Context Protocol client
- **Repository**: `crimson-knight/mcprotocol` (main branch)
- **Purpose**: MCP (Model Context Protocol) client for AI integrations
- **Use Case**: Connecting to MCP servers, tool execution, AI features

### Development Tools

**Ameba** - Crystal linter
- **Version**: ~> 1.5.0
- **Purpose**: Code quality, style checking
- **Usage**: `crystal tool format` and `ameba`

---

## 🏗️ Architecture Patterns

### MVC Pattern

This application follows Model-View-Controller architecture:

**Models** (`src/models/`)
- Grant ORM classes
- Business logic
- Validations
- Associations
- Example: `Users::Regular`, `Users::Admin`

**Views** (`src/views/components/`)
- **NOT string templates** - Object-oriented components
- Type-safe, testable, cacheable
- Built using AssetPipeline component system
- See skills for detailed component patterns

**Controllers** (`src/controllers/`)
- HTTP request handling
- Authentication/authorization
- Data flow: Controller → Component → Response
- Inherit from `ApplicationController`

### Component-Based Views (Critical Pattern)

**This application does NOT use ERB/ECR templates. It uses object-oriented components.**

**Old Pattern (Don't do this):**
```crystal
# ❌ NO string templates like this
render("views/home.ecr")
```

**New Pattern (Do this):**
```crystal
# ✅ Build components
page = Components::Pages::HomePageComponent.new(
  logged_in: logged_in?.to_s,
  user_email: current_user.try(&.email)
)

# Wrap in layout
layout = Components::Layouts::ApplicationLayout.new(
  title: "Home",
  content: page.render,
  current_path: request.path,
  flash_success: flash[:success]?
)

# Send to browser
context.response.content_type = "text/html"
context.response.print layout.render
```

**Why Components?**
- Type safety (Crystal compile-time checks)
- Testable (unit test each component)
- Cacheable (500x performance boost for stateless components)
- Reusable (compose large from small)
- Clear boundaries (data-component attributes for debugging/testing)

**See Skills:**
- `.claude/skills/asset-pipeline-components.md` - How to build components
- `.claude/skills/asset-pipeline-element-reference.md` - Element/attribute reference

### Data Flow Pattern

**Controller → Model → Component → HTML**

```crystal
class DashboardController < ApplicationController
  def index
    # 1. Fetch data from model
    user = current_user
    stats = User.count

    # 2. Create component with data
    page = Components::Pages::DashboardComponent.new(
      user_name: user.name,
      user_count: stats.to_s
    )

    # 3. Wrap in layout
    layout = Components::Layouts::ApplicationLayout.new(
      title: "Dashboard",
      content: page.render
    )

    # 4. Send response
    context.response.content_type = "text/html"
    context.response.print layout.render
  end
end
```

**Key Rules:**
- ✅ Pass data from controller to components via attributes
- ❌ Never access database/session directly in components
- ✅ Components should be pure functions (stateless) when possible
- ✅ Always escape user content (`escape_html()`)
- ✅ Always add `data-component` attributes to component root elements

### Authentication Pattern

**Multi-User Type System** - Using Grant ORM

This template supports multiple user types:
- `Users::Regular` - Standard users
- `Users::Admin` - Admin users with API access

**Tables:**
- `regular_users` - Regular user accounts
- `admin_users` - Admin accounts with API credentials

**Union Type:**
```crystal
alias CurrentUser = Users::Regular | Users::Admin
```

**Authentication:**
```crystal
# In controllers
def current_user : CurrentUser?
  # Returns Users::Regular or Users::Admin or nil
end

def logged_in? : Bool
  !current_user.nil?
end

# Type checking
if user.is_a?(Users::Admin)
  # Admin-specific logic
end
```

**Password Hashing:**
- Uses BCrypt
- Stored in `password_digest` column
- Authenticate via `User.authenticate(email, password)`

### Database Configuration Pattern

**Environment-Based Configuration** (No YAML Processing)

`config/database.cr` uses direct ENV variables:

```crystal
database_name = ENV["DB_NAME"]? || "app_#{APP_ENV}"
host = ENV["DB_HOST"]? || "localhost"
port = ENV["DB_PORT"]?.try(&.to_i) || 5432
username = ENV["DB_USER"]? || `whoami`.strip || "postgres"
password = ENV["DB_PASSWORD"]? || ""

Grant::Connections << Grant::Adapter::Pg.new(
  name: "pg",
  url: "postgres://#{username}:#{password}@#{host}:#{port}/#{database_name}"
)
```

**Why this approach:**
- Crystal doesn't natively support ERB-style YAML processing
- ENV variables are more secure (12-factor app)
- Simpler, more explicit configuration
- Works in development, test, production

**Grant Connections API:**
```crystal
# Get connection (returns NamedTuple with :writer and :reader)
connection = Grant::Connections["pg"]

# Execute query
connection[:writer].open do |db|
  db.exec("SQL query here")
end
```

### Routing Pattern

Routes defined in `config/routes.cr`:

```crystal
Amber::Server.configure do
  routes :web do
    # Public routes
    get "/", HomeController, :index
    get "/login", LoginController, :new
    post "/login", LoginController, :create

    # Authenticated routes
    get "/dashboard", DashboardController, :index
    get "/settings", SettingsController, :index
  end
end
```

### Testing Pattern

**Component Testing:**
```crystal
# spec/components/shared/button_component_spec.cr
describe Components::Shared::ButtonComponent do
  it "renders with attributes" do
    button = Components::Shared::ButtonComponent.new(
      label: "Test",
      variant: "primary"
    )

    rendered = button.render
    rendered.should contain("Test")
    rendered.should contain("btn-primary")
    rendered.should contain("data-component=\"button\"")
  end
end
```

**Controller Testing:**
```crystal
# spec/controllers/home_controller_spec.cr
class HomeControllerSpec
  include RequestHelper
  include TestHelpers

  def handler
    Amber::Server.instance.handler
  end
end

describe "HomeController" do
  spec = HomeControllerSpec.new

  it "renders homepage" do
    response = spec.get("/")
    response.status_code.should eq(200)
  end
end
```

**Database Cleanup:**
```crystal
# spec/spec_helper.cr
Spec.before_each do
  connection = Grant::Connections["pg"]
  if connection
    connection[:writer].open do |db|
      db.exec("TRUNCATE TABLE regular_users, admin_users RESTART IDENTITY CASCADE")
    end
  end
end
```

---

## 🔧 Configuration Files

### Key Configuration Files

**`config/database.cr`** - Database connection setup
- ENV-based configuration
- Grant ORM connections
- No YAML processing

**`config/routes.cr`** - Application routes
- RESTful routing
- Pipeline configuration
- Route definitions

**`config/application.cr`** - Main application file
- Requires all dependencies
- Sets up Amber server
- Loads configuration

**`shard.yml`** - Crystal dependency management
- All library versions
- Development dependencies
- Build targets

### Environment Files

**`.amber.yml`** - Amber configuration
- Database settings (reference only)
- Session configuration
- Logging settings

**`database.yml`** - Database configuration (reference only)
- ⚠️ NOT processed by Crystal
- Contains ERB-style templates
- Actual config is in `config/database.cr`

---

## 📁 Directory Structure

```
src/
  controllers/          # HTTP request handlers
  models/              # Grant ORM models
    users/             # User models (Regular, Admin)
  views/
    components/        # AssetPipeline components (NOT templates!)
      shared/          # Reusable UI components
      layouts/         # Page structure
      pages/           # Full page views
      forms/           # Form components

spec/                  # Test files (mirror src structure)
  controllers/
  components/
  models/

config/                # Application configuration
  database.cr          # Database setup (ENV-based)
  routes.cr           # Route definitions
  application.cr      # Main application file

db/
  migrations/         # SQL migration files

lib/                   # Dependencies (managed by shards)
  amber/
  grant/
  asset_pipeline/

public/                # Static assets
  css/
  js/
  images/

.claude/
  skills/              # Coding assistant skills
    asset-pipeline-components.md
    asset-pipeline-element-reference.md
```

---

## 🎯 Common Tasks & Patterns

### Creating a New Model

```crystal
# src/models/post.cr
class Post < Grant::Base
  connection pg
  table posts

  column id : Int64, primary: true
  column title : String
  column content : String
  column user_id : Int64
  timestamps

  belongs_to user : Users::Regular

  validate :title, "is required", ->(post : Post) {
    !post.title.empty?
  }
end
```

### Creating a New Component

```crystal
# src/views/components/shared/badge_component.cr
require "../../stateless_component"

module Components
  module Shared
    class BadgeComponent < StatelessComponent
      def render_content : String
        label = @attributes["label"]? || "Badge"
        variant = @attributes["variant"]? || "default"

        String.build do |html|
          html << "<span data-component=\"badge\" "
          html << "data-variant=\"#{variant}\" "
          html << "class=\"badge badge-#{variant}\">"
          html << "  #{escape_html(label)}"
          html << "</span>"
        end
      end

      def css_selector : String
        "[data-component='badge']"
      end
    end
  end
end
```

### Creating a New Controller

```crystal
# src/controllers/posts_controller.cr
class PostsController < ApplicationController
  def index
    posts = Post.all

    page = Components::Pages::PostsIndexComponent.new(
      posts: posts.map(&.to_json)
    )

    render_component(page, "Posts")
  end

  def show
    post = Post.find(params["id"])

    page = Components::Pages::PostShowComponent.new(
      title: post.title,
      content: post.content
    )

    render_component(page, post.title)
  end
end
```

### Adding a Route

```crystal
# config/routes.cr
Amber::Server.configure do
  routes :web do
    # RESTful resource
    resources "/posts", PostsController, except: [:destroy]

    # Custom routes
    get "/posts/:id/preview", PostsController, :preview
  end
end
```

### Creating a Migration

```bash
# Create migration file
touch db/migrations/$(date +%Y%m%d%H%M%S)_create_posts.sql
```

```sql
-- +micrate Up
CREATE TABLE posts (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  user_id BIGINT REFERENCES regular_users(id),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_posts_user_id ON posts(user_id);

-- +micrate Down
DROP TABLE IF EXISTS posts;
```

---

## 🚨 Critical Patterns to Follow

### 1. Component Data Attributes (REQUIRED)

Every component MUST include `data-component` attribute:

```crystal
# ✅ GOOD
html << "<div data-component=\"card\" class=\"card\">"

# ❌ BAD
html << "<div class=\"card\">"
```

### 2. HTML Escaping (SECURITY)

Always escape user content:

```crystal
# ✅ SAFE
html << escape_html(user_input)

# ❌ DANGEROUS (XSS vulnerability)
html << user_input
```

### 3. Database Access (ARCHITECTURE)

Never access database in components:

```crystal
# ❌ BAD - Database in component
class UserProfileComponent < StatelessComponent
  def render_content : String
    user = User.find(user_id)  # DON'T!
    # ...
  end
end

# ✅ GOOD - Pass data from controller
class UsersController < ApplicationController
  def show
    user = User.find(params["id"])

    profile = UserProfileComponent.new(
      user_name: user.name,
      user_email: user.email
    )

    render_component(profile)
  end
end
```

### 4. Grant Connection API

Use the correct Grant Connections API:

```crystal
# ✅ CORRECT
connection = Grant::Connections["pg"]
connection[:writer].open do |db|
  db.exec("SQL query")
end

# ❌ WRONG (old Granite API)
db = Granite::Connections["pg"]
db.exec("SQL query")
```

### 5. Stateless vs Stateful Components

Choose the right base class:

```crystal
# ✅ Use StatelessComponent when possible (auto-cached)
class ButtonComponent < StatelessComponent
  # Pure function, same inputs → same outputs
end

# ✅ Use StatefulComponent only when needed
class LoginFormComponent < StatefulComponent
  # Has state, manages user interactions
end
```

---

## 📖 Skills Available

Coding assistants have access to these comprehensive skills:

### `.claude/skills/asset-pipeline-components.md`
**Purpose**: How to build components
**Contains**:
- Component creation guide (step-by-step)
- Stateless vs Stateful patterns
- Data flow patterns
- Controller integration
- Testing patterns
- Common gotchas
- Best practices checklist

### `.claude/skills/asset-pipeline-element-reference.md`
**Purpose**: Complete HTML element & attribute reference
**Contains**:
- All 87 HTML5 elements with examples
- Complete attribute listings
- Constructor patterns (6 types)
- Global attributes reference
- Form-specific attributes
- Event handlers
- Security/escaping guidelines
- Common patterns (forms, tables, navigation, cards)

---

## 🔍 Quick Reference

### Run the Application

```bash
# Development
crystal src/agentc_app_template_oss.cr

# Watch mode (with sentry)
sentry -w "./src/**/*.cr" -w "./config/**/*.cr" \
  --run "crystal src/agentc_app_template_oss.cr"
```

### Run Tests

```bash
# All tests
crystal spec

# Single file
crystal spec spec/components/shared/button_component_spec.cr

# With coverage
crystal spec --error-trace
```

### Database Operations

```bash
# Create database
createdb agentc_app_template_oss_development
createdb agentc_app_template_oss_test

# Run migrations
AMBER_ENV=development ./sam db:migrate
AMBER_ENV=test ./sam db:migrate

# Or manually
psql -d agentc_app_template_oss_development -f db/migrations/file.sql
```

### Code Quality

```bash
# Format code
crystal tool format

# Lint code
ameba
```

---

## 🆘 Troubleshooting

### Grant Connection Errors

**Error**: `undefined method 'exec' for NamedTuple`

**Solution**: Grant returns `{writer: Adapter, reader: Adapter}`, not direct connection:

```crystal
# Fix:
connection = Grant::Connections["pg"]
connection[:writer].open do |db|
  db.exec("SQL")
end
```

### Missing Data Attributes

**Error**: Can't find component in tests/debugging

**Solution**: Always add `data-component` attribute:

```crystal
html << "<div data-component=\"component-name\">"
```

### Component Not Rendering

**Error**: Empty output from component

**Solution**: Check you're calling `.render` and building HTML correctly:

```crystal
component = MyComponent.new(attr: "value")
html = component.render  # Don't forget .render!
```

### Database User Errors

**Error**: `role "postgres" does not exist`

**Solution**: Update `config/database.cr` or set ENV:

```bash
export DB_USER=your_username
```

### XSS Vulnerabilities

**Error**: User content rendered as HTML

**Solution**: Always escape user input:

```crystal
html << escape_html(user_input)
```

---

## 📚 Additional Documentation

- **Amber**: `lib/amber/CLAUDE.md`
- **Grant**: `lib/grant/CLAUDE.md`
- **AssetPipeline**: `lib/asset_pipeline/CLAUDE.md`
- **Components**: `src/views/components/CLAUDE.md`
- **Project README**: `README.md`

---

**Remember**: This template uses object-oriented components, not string templates. Always refer to the component skills when building views!
