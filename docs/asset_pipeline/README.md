# Asset Pipeline Documentation

Modern JavaScript asset management using ESM modules and import maps for Crystal/Amber applications.

**Repository:** https://github.com/amberframework/asset_pipeline

---

## 🌟 Overview

Asset Pipeline provides a modern approach to frontend asset management:

- **ESM Modules** - Native ES6 module support
- **Import Maps** - Manage dependencies without bundlers
- **Stimulus Integration** - Pre-configured Stimulus JS setup
- **Turbo Support** - Optional seamless page navigation
- **Automatic Cache Clearing** - Smart cache management (v0.36.0+)
- **CDN Support** - Load dependencies from CDNs

---

## 🚀 Quick Start

### Configuration
Asset Pipeline is configured in `config/initializers/asset_pipeline.cr`:

```crystal
AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"],
  clear_cache_upon_change: Amber.env.development?
) do |import_maps|
  app_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])

  # Add Stimulus
  app_map.add_import(
    "@hotwired/stimulus",
    "https://unpkg.com/@hotwired/stimulus@3.2.2/dist/stimulus.js"
  )

  import_maps << app_map
end
```

### Directory Structure
```
src/javascript/
├── controllers/           # Stimulus controllers
│   ├── login_controller.js
│   └── user_form_controller.js
└── utils/                # Utility modules
    └── api.js

public/javascript/         # Compiled output (auto-generated)
```

---

## 📦 Features

### ESM Module Support
Write modern JavaScript with import/export:

```javascript
// src/javascript/utils/api.js
export class API {
  static async get(url) {
    const response = await fetch(url)
    return await response.json()
  }
}

// src/javascript/controllers/data_controller.js
import { API } from "../utils/api.js"

export default class extends Controller {
  async loadData() {
    const data = await API.get("/api/users")
    this.displayData(data)
  }
}
```

### Import Maps
Manage external dependencies without npm:

```crystal
# In config/initializers/asset_pipeline.cr
app_map.add_import(
  "@hotwired/stimulus",
  "https://unpkg.com/@hotwired/stimulus@3.2.2/dist/stimulus.js"
)

app_map.add_import(
  "@hotwired/turbo",
  "https://unpkg.com/@hotwired/turbo@7.3.0/dist/turbo.es2017-esm.js"
)
```

Then import in your JavaScript:
```javascript
import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo"
```

### Stimulus JS Integration
Pre-configured for Stimulus controllers:

```javascript
// src/javascript/controllers/hello_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "output"]

  greet() {
    this.outputTarget.textContent = `Hello, ${this.nameTarget.value}!`
  }
}
```

Register in your layout:
```ecr
<script type="module">
  import { Application } from "@hotwired/stimulus"
  import HelloController from "/javascript/controllers/hello_controller.js"

  window.Stimulus = Application.start()
  Stimulus.register("hello", HelloController)
</script>
```

---

## 🎨 Automatic Cache Clearing

Asset Pipeline v0.36.0+ includes smart cache management:

- **Development:** Cache cleared automatically on file changes
- **Production:** Cache clearing disabled for performance
- **Configurable:** Set `clear_cache_upon_change: false` to disable

Benefits:
- ✅ No manual cache clearing needed
- ✅ Always see latest changes in development
- ✅ Optimal performance in production

---

## 📚 Detailed Documentation

- **[Getting Started](getting-started.md)** - Setup and first module
- **[JavaScript Modules](javascript-modules.md)** - ESM syntax and patterns
- **[Import Maps](import-maps.md)** - Managing dependencies
- **[Cache Management](cache-management.md)** - Cache clearing strategies
- **[Examples](examples.md)** - Stimulus controllers and real-world usage

---

## 💡 Common Patterns

### Adding External Libraries
```crystal
# In asset_pipeline.cr
app_map.add_import(
  "chart.js",
  "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.js"
)
```

```javascript
// In your controller
import Chart from "chart.js"
```

### Creating Utility Modules
```javascript
// src/javascript/utils/helpers.js
export function formatDate(date) {
  return new Intl.DateTimeFormat('en-US').format(date)
}

export function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1)
}
```

### Turbo Integration (Optional)
```crystal
# Add to import map
app_map.add_import(
  "@hotwired/turbo",
  "https://unpkg.com/@hotwired/turbo@7.3.0/dist/turbo.es2017-esm.js"
)
```

No additional setup needed - Turbo works automatically!

---

## 🔗 Quick Links

- **Example Controller:** `src/javascript/controllers/user_form_controller.js`
- **Configuration:** `config/initializers/asset_pipeline.cr`
- **Layout Integration:** `src/views/layouts/application.ecr`
- **GitHub Repository:** https://github.com/amberframework/asset_pipeline

---

## 🎯 Next Steps

1. Read [Getting Started](getting-started.md) for detailed setup
2. Explore [JavaScript Modules](javascript-modules.md) to create modules
3. Review [Import Maps](import-maps.md) for dependency management
4. Check [Examples](examples.md) for Stimulus controller patterns

---

**Asset Pipeline brings modern JavaScript to Crystal/Amber applications.**
