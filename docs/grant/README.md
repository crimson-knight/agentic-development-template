# Grant ORM Documentation

Grant is a full-featured, ActiveRecord-style ORM for Crystal with near feature parity to Rails ActiveRecord.

**Repository:** https://github.com/crimson-knight/grant

---

## 🌟 Feature Comparison

Grant provides comprehensive ORM features comparable to ActiveRecord:

| Feature | Grant | ActiveRecord | Notes |
|---------|-------|--------------|-------|
| **Associations** |
| belongs_to | ✅ | ✅ | Full support with dependent options |
| has_one | ✅ | ✅ | Including dependent: :destroy/:nullify |
| has_many | ✅ | ✅ | With all dependent options |
| has_many :through | ✅ | ✅ | Join table associations |
| Polymorphic | ✅ | ✅ | Interface-based polymorphism |
| **Validations** |
| validates_presence_of | ✅ | ✅ | |
| validates_uniqueness_of | ✅ | ✅ | |
| validates_length_of | ✅ | ✅ | min/max/in range |
| validates_numericality_of | ✅ | ✅ | greater_than, less_than, etc. |
| validates_email | ✅ | ❌ | Grant-specific |
| validates_format_of | ✅ | ✅ | Regex validation |
| validates_inclusion_of | ✅ | ✅ | |
| Custom validations | ✅ | ✅ | |
| **Security** |
| encrypts | ✅ | ✅ | Encrypted attributes |
| has_secure_token | ✅ | ✅ | Token generation |
| SignedId | ✅ | ✅ | Signed IDs for URLs |
| TokenFor | ✅ | ✅ | Time-based tokens |
| normalizes | ✅ | ✅ | Data normalization |
| **Callbacks** |
| before_validation | ✅ | ✅ | |
| before_save | ✅ | ✅ | |
| after_create | ✅ | ✅ | |
| after_commit | ✅ | ✅ | |
| All lifecycle callbacks | ✅ | ✅ | |
| **Query Interface** |
| where, find, find_by | ✅ | ✅ | |
| order, limit, offset | ✅ | ✅ | |
| Scopes | ✅ | ✅ | |
| default_scope | ✅ | ✅ | |
| Eager loading | ✅ | ✅ | |
| **Advanced Features** |
| Enum attributes | ✅ | ✅ | |
| Serialized columns | ✅ | ✅ | JSON/YAML |
| Transactions | ✅ | ✅ | |
| Optimistic locking | ✅ | ✅ | |
| Pessimistic locking | ✅ | ✅ | with_lock |
| Dirty tracking | ✅ | ✅ | changed?, *_was, etc. |
| Attribute API | ✅ | ✅ | Virtual attributes |
| Value objects | ✅ | ✅ | aggregation |
| Sharding | ✅ | ✅ | Multi-database support |

---

## 🚀 Quick Start

### Installation
Grant is already configured in this template. Configuration is in:
- `config/database.cr` - Database connection
- `config/initializers/grant.cr` - Additional Grant settings

### Your First Model
```crystal
require "grant"

class Article < Grant::Base
  connection pg
  table articles

  column id : Int64, primary: true
  column title : String
  column content : String
  column published : Bool = false

  validates_presence_of :title, :content
  validates_length_of :title, minimum: 5, maximum: 100

  timestamps
end
```

### Usage
```crystal
# Create
article = Article.new(title: "Hello Grant", content: "...")
article.save

# Read
Article.all
Article.find(1)
Article.find_by(title: "Hello Grant")

# Update
article.title = "Updated Title"
article.save

# Delete
article.destroy
```

---

## 📚 Detailed Documentation

Explore the comprehensive guides for each feature:

### Core Features
- **[Getting Started](getting-started.md)** - Installation, configuration, first model
- **[Associations](associations.md)** - belongs_to, has_many, polymorphic associations
- **[Validations](validations.md)** - All validators and custom validations
- **[Callbacks](callbacks.md)** - Lifecycle hooks and transaction callbacks

### Advanced Features
- **[Security Features](security-features.md)** - Encryption, tokens, signed IDs
- **[Advanced Features](advanced-features.md)** - Enums, scopes, transactions, locking
- **[Complete Examples](examples.md)** - Full model examples with all features

---

## 💡 Key Concepts

### Connections
Grant uses named connections. This template uses `pg` for PostgreSQL:
```crystal
connection pg  # Defined in your model
```

### Timestamps
Automatically manage created_at and updated_at:
```crystal
timestamps  # Adds both columns and auto-updates
```

### Scopes
Create reusable query methods:
```crystal
scope :published, ->{ where(published: true) }
scope :recent, ->{ order(created_at: :desc).limit(10) }

# Usage
Article.published.recent
```

### Enum Attributes
Type-safe enumerations:
```crystal
enum Status
  Draft
  Published
  Archived
end

enum_attribute status : Status = :draft

# Provides: article.draft?, article.published!, Article.published.all
```

---

## 🔗 Quick Links

- **Example Model:** `src/models/user.cr`
- **Configuration:** `config/initializers/grant.cr`
- **GitHub Repository:** https://github.com/crimson-knight/grant

---

## 🎯 Next Steps

1. Read [Getting Started](getting-started.md) for detailed setup
2. Explore [Associations](associations.md) to model relationships
3. Review [Security Features](security-features.md) for data protection
4. Check [Examples](examples.md) for complete working code

---

**Grant is production-ready and actively maintained.**
