# Gemma File Attachments Documentation

Gemma is a flexible file attachment library for Crystal with seamless Grant ORM integration and multiple storage backends.

**Repository:** https://github.com/crimson-knight/gemma

---

## 🌟 Overview

Gemma makes file uploads simple while providing powerful features:

- **Simple API** - `has_one_attached` and `has_many_attached` macros
- **Multiple Storage Backends** - Filesystem, S3, S3-compatible services
- **Grant Integration** - First-class support for Grant ORM models
- **Validations** - File size, content type, and dimension validation
- **Plugin System** - Extensible with custom processors
- **Direct Uploads** - Support for client-side uploads to S3

---

## 🚀 Quick Start

### Configuration
Gemma is already configured in `config/initializers/gemma.cr`:
- **Development/Test:** Filesystem storage in `public/uploads/`
- **Production:** S3-compatible storage (configured via ENV variables)

### Basic Usage

#### 1. Add to Your Model
```crystal
require "gemma/grant"

class User < Grant::Base
  include Gemma::Grant::Attachable
  include Gemma::Grant::AttachmentValidators

  column id : Int64, primary: true
  column name : String
  column avatar_data : JSON::Any?

  has_one_attached :avatar

  validate_file_size_of :avatar, maximum: 5.megabytes
  validate_content_type_of :avatar, accept: ["image/jpeg", "image/png"]
end
```

#### 2. Handle Uploads in Controller
```crystal
def create
  user = User.new(user_params)

  if avatar = params.files["avatar"]?
    user.avatar = avatar.file
  end

  user.save
  redirect_to "/users/#{user.id}"
end
```

#### 3. Display in Views
```ecr
<% if user.avatar %>
  <img src="<%= user.avatar.url %>" alt="Avatar">
<% end %>
```

---

## 📚 Features

### Single File Attachment
```crystal
column avatar_data : JSON::Any?
has_one_attached :avatar

# Usage
user.avatar = File.open("photo.jpg")
user.save

# Access
user.avatar.url      # => "/uploads/users/1/avatar/abc123.jpg"
user.avatar.filename # => "photo.jpg"
user.avatar.size     # => 12345
```

### Multiple File Attachments
```crystal
column documents_data : JSON::Any?
has_many_attached :documents

# Usage
user.documents = [File.open("doc1.pdf"), File.open("doc2.pdf")]
user.save

# Access
user.documents.each do |doc|
  puts doc.url
  puts doc.filename
end
```

### File Validations
```crystal
# Size validation
validate_file_size_of :avatar, maximum: 5.megabytes
validate_file_size_of :avatar, minimum: 100.kilobytes, maximum: 5.megabytes

# Content type validation
validate_content_type_of :avatar, accept: ["image/jpeg", "image/png"]
validate_content_type_of :document, reject: ["application/x-msdownload"]
```

---

## 🗄️ Storage Backends

### Filesystem (Development)
```crystal
config.storages["store"] = Gemma::Storage::FileSystem.new("public/uploads")
```

### S3 (Production)
```crystal
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
```

Configure with environment variables in `.env`:
```bash
S3_REGION=us-east-1
S3_KEY=your_access_key
S3_SECRET=your_secret_key
S3_BUCKET=your_bucket_name
S3_ENDPOINT=https://s3.amazonaws.com  # Optional
```

---

## 🔌 Plugin System

### Determine MIME Type
```crystal
load_plugin(
  Gemma::Plugins::DetermineMimeType,
  analyzer: Gemma::Plugins::DetermineMimeType::Tools::File
)
```

### Store Image Dimensions
```crystal
# Requires fastimage shard
load_plugin(
  Gemma::Plugins::StoreDimensions,
  analyzer: Gemma::Plugins::StoreDimensions::Tools::FastImage
)
```

---

## 📚 Detailed Documentation

- **[Getting Started](getting-started.md)** - Setup and first upload
- **[Storage Backends](storage-backends.md)** - Filesystem, S3 configuration
- **[Grant Integration](grant-integration.md)** - Complete integration guide
- **[Plugins](plugins.md)** - Available plugins and custom plugins
- **[Examples](examples.md)** - Real-world usage examples

---

## 💡 Common Patterns

### Removing Files
```crystal
user.avatar.destroy if user.avatar
user.avatar_data = nil
user.save
```

### Conditional File Upload
```crystal
if avatar = params.files["avatar"]?
  user.avatar = avatar.file
end

# Remove if checkbox checked
if params["remove_avatar"]? == "1"
  user.avatar.destroy if user.avatar
  user.avatar_data = nil
end
```

### File Metadata
```crystal
user.avatar.metadata["content_type"]  # => "image/jpeg"
user.avatar.metadata["size"]          # => "12345"
user.avatar.metadata["filename"]      # => "photo.jpg"
```

---

## 🔗 Quick Links

- **Example Model:** `src/models/user.cr`
- **Example Controller:** `src/controllers/users_controller.cr`
- **Configuration:** `config/initializers/gemma.cr`
- **GitHub Repository:** https://github.com/crimson-knight/gemma

---

## 🎯 Next Steps

1. Read [Getting Started](getting-started.md) for detailed setup
2. Explore [Grant Integration](grant-integration.md) for model integration
3. Review [Storage Backends](storage-backends.md) for production setup
4. Check [Examples](examples.md) for complete working code

---

**Gemma is production-ready and actively maintained.**
