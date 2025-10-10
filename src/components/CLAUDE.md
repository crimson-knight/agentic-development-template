# Application Components

This directory contains our application-specific components built using the Asset Pipeline component system.

---

## Directory Structure

```
src/components/
  shared/           # Reusable components used throughout the app
  layouts/          # Layout components (navigation, footers, etc.)
  pages/            # Full page components
  forms/            # Form components with validation
```

---

## Component Patterns

### Naming Conventions

- Component files: `component_name_component.cr` (e.g., `button_component.cr`)
- Class names: `ComponentNameComponent` (e.g., `ButtonComponent`)
- Modules: Components are namespaced under `Components::{Category}` (e.g., `Components::Shared::ButtonComponent`)

### File Structure Pattern

```crystal
require "../../../lib/asset_pipeline/src/components/base/stateless_component"
require "../../../lib/asset_pipeline/src/components/elements/..." # Required elements

module Components
  module Shared  # or Layouts, Pages, Forms
    # Component documentation with usage examples
    class ComponentNameComponent < StatelessComponent  # or StatefulComponent
      def render_content : String
        # Extract attributes
        prop1 = @attributes["prop1"]? || "default"

        # Build HTML using Elements
        element = Elements::Div.new(class: "component-class")
        element << prop1

        # Render children if needed
        @children.each do |child|
          append_child(element, child)
        end

        element.render
      end

      # Optional: CSS selector for testing
      def css_selector : String
        ".component-class"
      end

      private def append_child(parent, child)
        case child
        when Component
          parent << child.render
        when Elements::HTMLElement
          parent << child
        when String
          parent << child
        end
      end
    end
  end
end
```

### Test File Structure

Tests live in matching `spec/components/{category}/` directory:

```crystal
require "../component_spec_helper"
require "../../../src/components/shared/component_name_component"

describe Components::Shared::ComponentNameComponent do
  describe "rendering" do
    it "renders with default attributes" do
      component = Components::Shared::ComponentNameComponent.new
      component.render.should contain("expected-content")
    end

    it "accepts custom attributes" do
      component = Components::Shared::ComponentNameComponent.new(prop1: "custom")
      component.render.should contain("custom")
    end
  end

  describe "css_selector" do
    it "returns correct selector" do
      component = Components::Shared::ComponentNameComponent.new
      component.css_selector.should eq(".component-class")
    end
  end
end
```

---

## Component Categories

### Shared Components (`src/components/shared/`)

Reusable, generic components used throughout the application.

**Examples:**
- `ButtonComponent` - Buttons with variants, sizes, icons
- `CardComponent` - Content cards with title, image, body
- `StatCardComponent` - Dashboard statistics cards
- `IconComponent` - SVG icon wrapper
- `FlashMessageComponent` - Alert/notification messages

**Characteristics:**
- Should be stateless when possible
- Accept all configuration via attributes
- No business logic - only presentation
- Highly testable and cacheable

**Usage Pattern:**
```crystal
button = Components::Shared::ButtonComponent.new(
  label: "Save",
  variant: "primary",
  icon: "💾"
)
html = button.render
```

### Layout Components (`src/components/layouts/`)

Components that define page structure and common UI elements.

**Examples:**
- `ApplicationLayout` - Main HTML structure, head, body
- `NavigationComponent` - Top navigation bar
- `SessionInfoComponent` - User session display (login/logout)
- `FooterComponent` - Page footer
- `SidebarComponent` - Sidebar navigation

**Characteristics:**
- Usually stateless
- Accept content via `content` attribute or children
- May compose multiple smaller components

**Usage Pattern:**
```crystal
nav = Components::Layouts::NavigationComponent.new(
  current_path: "/dashboard",
  current_user: current_user
)

layout = Components::Layouts::ApplicationLayout.new(
  title: "Dashboard",
  content: page_component.render,
  navigation: nav.render
)
```

### Page Components (`src/components/pages/`)

Full-page components that represent entire views.

**Examples:**
- `HomePageComponent` - Landing page
- `DashboardComponent` - User dashboard
- `SettingsPageComponent` - User settings page

**Characteristics:**
- Compose multiple shared and layout components
- Accept user data and state via attributes
- Represent complete pages

**Usage Pattern:**
```crystal
# In controller:
def index
  page = Components::Pages::HomePageComponent.new(
    logged_in: logged_in?,
    current_user: current_user
  )

  layout = Components::Layouts::ApplicationLayout.new(
    title: "Welcome",
    content: page.render
  )

  render html: layout.render
end
```

### Form Components (`src/components/forms/`)

Interactive forms with validation.

**Examples:**
- `LoginFormComponent` - Email/password login
- `RegistrationFormComponent` - User registration
- `SettingsFormComponent` - User settings update

**Characteristics:**
- Usually stateful (manage form state)
- Implement validation logic
- Handle field changes and submissions
- Integrate with CSRF tokens

**Usage Pattern:**
```crystal
form = Components::Forms::LoginFormComponent.new(
  csrf_token: csrf_token,
  email_value: params["email"]?
)
html = form.render
```

---

## Important Conventions

### 1. Always Require What You Need

Each component file must explicitly require its dependencies:

```crystal
# Base class
require "../../../lib/asset_pipeline/src/components/base/stateless_component"

# Elements you'll use
require "../../../lib/asset_pipeline/src/components/elements/grouping/div"
require "../../../lib/asset_pipeline/src/components/elements/forms/form_controls"
require "../../../lib/asset_pipeline/src/components/elements/text/a"
```

### 2. Use Elements, Not HTML Strings

**Good:**
```crystal
div = Elements::Div.new(class: "container")
div << "Content"
div.render
```

**Bad:**
```crystal
"<div class='container'>Content</div>"  # Don't do this!
```

**Why:** Type safety, attribute escaping, testability, CSS introspection

### 3. Extract Attributes Early

Start your `render_content` method by extracting all attributes with defaults:

```crystal
def render_content : String
  # Extract all attributes at the top
  title = @attributes["title"]? || "Default Title"
  variant = @attributes["variant"]? || "primary"
  size = @attributes["size"]? || "medium"
  show_icon = @attributes["show_icon"]? == "true"

  # Then build the component
  # ...
end
```

### 4. Provide CSS Selectors for Testing

Always implement `css_selector` for shared components:

```crystal
def css_selector : String
  variant = @attributes["variant"]? || "primary"
  size = @attributes["size"]? || "medium"
  ".btn.btn-#{variant}.btn-#{size}"
end
```

### 5. Handle Children Properly

If your component accepts children, handle all three types:

```crystal
@children.each do |child|
  case child
  when Component
    element << child.render
  when Elements::HTMLElement
    element << child
  when String
    element << child
  end
end
```

### 6. Test Every Component

Every component needs:
- ✅ Rendering tests (default and with custom attributes)
- ✅ CSS selector tests (if applicable)
- ✅ Caching tests (for stateless components)
- ✅ State management tests (for stateful components)

---

## Integration with Controllers

### Basic Pattern

```crystal
class MyController < ApplicationController
  def index
    component = Components::Pages::MyPageComponent.new(
      user: current_user,
      data: some_data
    )

    render html: component.render
  end
end
```

### With Layout

```crystal
class MyController < ApplicationController
  def index
    page = Components::Pages::MyPageComponent.new(
      user: current_user
    )

    layout = Components::Layouts::ApplicationLayout.new(
      title: "Page Title",
      flash: flash.to_h,
      content: page.render
    )

    render html: layout.render
  end
end
```

### Helper Method Pattern

Create a helper in `ApplicationController`:

```crystal
abstract class ApplicationController < Amber::Controller::Base
  def render_component(component : Components::Component, title : String = "AgentC")
    layout = Components::Layouts::ApplicationLayout.new(
      title: title,
      flash: flash.to_h,
      current_user: current_user,
      content: component.render
    )

    render html: layout.render
  end
end

# Usage in controllers:
def index
  page = Components::Pages::DashboardComponent.new(user: current_user)
  render_component(page, title: "Dashboard")
end
```

---

## Component Testing

### Test Helper

Use `spec/components/component_spec_helper.cr`:

```crystal
require "spec"
require "../../lib/asset_pipeline/src/asset_pipeline"
```

This provides:
- Asset Pipeline component system
- No database dependencies
- Fast, isolated testing

### Running Tests

```bash
# Test single component
crystal spec spec/components/shared/button_component_spec.cr

# Test all components
crystal spec spec/components/

# Test with verbose output
crystal spec spec/components/ --verbose
```

---

## Best Practices

### ✅ DO

- **Make components small and focused** - One responsibility per component
- **Use stateless components when possible** - They're automatically cached
- **Provide sensible defaults** - Components should work with minimal configuration
- **Document component attributes** - Use comments to explain what each attribute does
- **Write comprehensive tests** - Test all rendering paths and edge cases
- **Use semantic HTML** - Choose appropriate HTML elements
- **Escape user content** - Elements handle this automatically

### ❌ DON'T

- **Don't mix concerns** - Keep business logic in controllers/models
- **Don't hardcode values** - Accept configuration via attributes
- **Don't use HTML strings** - Use Elements classes
- **Don't access database** - Components receive data via attributes
- **Don't access session/cookies** - Pass data from controller
- **Don't use global state** - Components should be pure functions

---

## Examples from This Application

### ButtonComponent (Shared)

**File:** `src/components/shared/button_component.cr`

**Features:**
- Variants: primary, secondary, danger
- Sizes: small, medium, large
- Icon support
- Can render as `<button>` or `<a>` (link styled as button)
- Disabled state
- Custom CSS classes

**Usage:**
```crystal
# Basic button
Components::Shared::ButtonComponent.new(label: "Click Me")

# Danger button with icon
Components::Shared::ButtonComponent.new(
  label: "Delete",
  variant: "danger",
  icon: "🗑️",
  size: "small"
)

# Link styled as button
Components::Shared::ButtonComponent.new(
  label: "Go to Dashboard",
  href: "/dashboard",
  variant: "primary"
)
```

**Test Coverage:** 14 tests (all passing)
- 8 rendering tests
- 3 CSS selector tests
- 3 caching tests

---

## Future Components

Based on `VIEW_MIGRATION_PLAN.md`, these components are planned:

**Shared:**
- CardComponent
- StatCardComponent
- IconComponent
- FlashMessageComponent

**Layouts:**
- ApplicationLayout
- NavigationComponent
- SessionInfoComponent

**Pages:**
- HomePageComponent
- DashboardComponent

**Forms:**
- LoginFormComponent

See `VIEW_MIGRATION_PLAN.md` for detailed specifications.

---

## References

- **Asset Pipeline Docs:** `lib/asset_pipeline/CLAUDE.md`
- **Migration Plan:** `VIEW_MIGRATION_PLAN.md`
- **Component Examples:** `lib/asset_pipeline/src/components/examples/`
- **Test Examples:** `spec/components/`

---

**Last Updated:** 2025-10-10
**Components Implemented:** 1 (ButtonComponent)
**Test Coverage:** 100% for implemented components
