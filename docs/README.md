# Agentic Development Template - Documentation

This template comes pre-configured with three powerful shards that work together to create a modern, full-stack Crystal/Amber application:

## 🎯 Integrated Shards

### 1. **Grant ORM** - Database Modeling
A full-featured, ActiveRecord-style ORM for Crystal with feature parity to Rails ActiveRecord.

- [Grant Documentation →](grant/README.md)
- Repository: https://github.com/crimson-knight/grant

**Key Features:**
- Associations (belongs_to, has_many, has_many :through, polymorphic)
- Validations (20+ built-in validators)
- Security (encrypted attributes, secure tokens, signed IDs)
- Callbacks & Transactions
- Scopes & Query Interface
- Dirty Tracking & Enums

### 2. **Gemma** - File Attachments
Flexible file attachment library with seamless Grant ORM integration and multiple storage backends.

- [Gemma Documentation →](gemma/README.md)
- Repository: https://github.com/crimson-knight/gemma

**Key Features:**
- Simple file attachment API (`has_one_attached`, `has_many_attached`)
- Multiple storage backends (Filesystem, S3, S3-compatible)
- File validations (size, content type, dimensions)
- Plugin system for metadata extraction
- Direct uploads & streaming

### 3. **Asset Pipeline** - Frontend Assets
Modern JavaScript asset management using ESM modules and import maps.

- [Asset Pipeline Documentation →](asset_pipeline/README.md)
- Repository: https://github.com/amberframework/asset_pipeline

**Key Features:**
- ESM module support
- Import maps for dependency management
- Stimulus JS integration
- Turbo for SPA-like navigation
- Automatic cache management

---

## 📚 Quick Start Guide

### 1. Install Dependencies
```bash
shards install
```

### 2. Configure Database
Copy `.env.example` to `.env` and configure your database:
```bash
cp .env.example .env
# Edit .env with your database credentials
```

### 3. Run Migrations
```bash
amber db migrate
```

### 4. Start Development Server
```bash
amber watch
```

---

## 🏗️ Architecture Overview

### Database Layer (Grant ORM)
- Models in `src/models/`
- Example: `src/models/user.cr` demonstrates all Grant features
- Configuration: `config/database.cr`, `config/initializers/grant.cr`

### File Storage (Gemma)
- Filesystem storage for development
- S3 storage for production
- Configuration: `config/initializers/gemma.cr`

### Frontend Assets (Asset Pipeline)
- JavaScript in `src/javascript/`
- Compiled to `public/javascript/`
- Configuration: `config/initializers/asset_pipeline.cr`

---

## 📖 Documentation Structure

### By Feature
- **[Grant ORM](grant/)** - Database models, associations, validations
- **[Gemma](gemma/)** - File uploads and storage
- **[Asset Pipeline](asset_pipeline/)** - JavaScript and frontend assets

### By Use Case
- **[Integration Examples](integration/full-stack-examples.md)** - Complete examples using all three shards
- **[Best Practices](integration/best-practices.md)** - Recommended patterns and architecture
- **[Troubleshooting](integration/troubleshooting.md)** - Common issues and solutions

---

## 🎓 Learning Path

**For Beginners:**
1. Start with [Grant Getting Started](grant/getting-started.md)
2. Read [Gemma Getting Started](gemma/getting-started.md)
3. Explore [Asset Pipeline Getting Started](asset_pipeline/getting-started.md)
4. Review the example User model in `src/models/user.cr`

**For Experienced Developers:**
1. Review [Grant Advanced Features](grant/advanced-features.md)
2. Study [Grant Security Features](grant/security-features.md)
3. Explore [Gemma Grant Integration](gemma/grant-integration.md)
4. Check [Integration Best Practices](integration/best-practices.md)

---

## 💡 Quick Examples

### Creating a Model with File Attachments
```crystal
class Post < Grant::Base
  include Gemma::Grant::Attachable

  connection pg
  table posts

  column id : Int64, primary: true
  column title : String
  column images_data : JSON::Any?

  has_many_attached :images
  validate_file_size_of :images, maximum: 5.megabytes

  timestamps
end
```

### Controller with File Uploads
```crystal
def create
  post = Post.new(post_params)

  if images = params.files.get_all("images")
    post.images = images.map(&.file)
  end

  post.save
  redirect_to "/posts/#{post.id}"
end
```

### Stimulus Controller
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Connected!")
  }
}
```

---

## 🔗 Additional Resources

- **Example Files:**
  - `src/models/user.cr` - Comprehensive model example
  - `src/controllers/users_controller.cr` - CRUD with file uploads
  - `src/javascript/controllers/user_form_controller.js` - File validation

- **Configuration Files:**
  - `config/initializers/grant.cr` - Grant ORM setup
  - `config/initializers/gemma.cr` - Gemma storage configuration
  - `config/initializers/asset_pipeline.cr` - Frontend asset setup

---

## 🆘 Getting Help

- Check [Troubleshooting Guide](integration/troubleshooting.md)
- Review example files in the codebase
- Consult the detailed documentation for each shard
- Open an issue on the respective GitHub repositories

---

**Last Updated:** 2025-10-10
