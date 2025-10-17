# Views Directory

This directory contains all view-related code for the application, following Rails-inspired conventions.

---

## Directory Structure

```
src/views/
  components/           # Component-based view system (100% of views)
    shared/            # Reusable UI components
    layouts/           # Page layouts and structure
    pages/             # Full page components
    forms/             # Form components with validation
    CLAUDE.md          # Component system documentation
  CLAUDE.md            # This file
```

---

## Component System

**This application uses 100% component-based views.**

- ✅ **No ECR templates** - All views are Crystal components
- ✅ **Type-safe** - Compile-time checking for all views
- ✅ **Testable** - Unit test components without browser
- ✅ **Reusable** - DRY principles throughout

See `src/views/components/CLAUDE.md` for complete component documentation.

---

## Rails-Inspired Conventions

### Naming Conventions

**Files:**
- Component files: `component_name_component.cr`
- Spec files: `component_name_component_spec.cr`
- Use snake_case for all file names

**Classes:**
- Component classes: `ComponentNameComponent`
- Use PascalCase for class names
- Namespace: `Components::{Category}::{ComponentName}Component`

**Examples:**
```
src/views/components/shared/button_component.cr
→ class Components::Shared::ButtonComponent

src/views/components/forms/login_form_component.cr
→ class Components::Forms::LoginFormComponent
```

### Directory Organization

Follow Rails-style organization by component type:

- `shared/` - Reusable UI components (buttons, cards, icons)
- `layouts/` - Page structure components (headers, navs, layouts)
- `pages/` - Full page components (home, dashboard, settings)
- `forms/` - Form components with validation

---

## Data Attribute Conventions

**IMPORTANT:** All components must include identifying data attributes on their outermost wrapper element.

### Why Data Attributes?

1. **Easy to find in DOM** - `document.querySelector('[data-component="button"]')`
2. **Testable** - Easy to target in tests
3. **Debuggable** - Know what component rendered what HTML
4. **Stimulus integration** - Natural pairing with Stimulus controllers
5. **Clear ownership** - Know which component owns which markup

### Standard Data Attributes

Every component MUST include:

```html
<div data-component="component-name" data-component-id="unique-id">
  <!-- Component content -->
</div>
```

**Required attributes:**
- `data-component` - Component name in kebab-case
- `data-component-id` - Unique identifier (optional but recommended)

**Optional attributes:**
- `data-variant` - For components with variants (primary, secondary, etc.)
- `data-state` - For stateful components (loading, error, success)
- `data-testid` - For test targeting

### Examples

**Button Component:**
```html
<button data-component="button"
        data-variant="primary"
        data-size="medium"
        type="button">
  Click Me
</button>
```

**Card Component:**
```html
<div data-component="card"
     data-component-id="feature-card-1">
  <!-- Card content -->
</div>
```

**Form Component:**
```html
<form data-component="login-form"
      data-state="idle"
      action="/login" method="POST">
  <!-- Form fields -->
</form>
```

### Implementation Pattern

In your component's `render_content` method:

```crystal
def render_content : String
  # Extract attributes
  variant = @attributes["variant"]? || "primary"

  # Build with data attributes
  String.build do |html|
    html << "<div data-component=\"my-component\" "
    html << "data-variant=\"#{variant}\">"
    html << "  <!-- Content -->"
    html << "</div>"
  end
end
```

---

## Component Categories

### Shared Components (`shared/`)

Small, reusable UI elements used throughout the app.

**Examples:** ButtonComponent, IconComponent, CardComponent

**Characteristics:**
- Single responsibility
- Highly reusable
- Stateless when possible
- Accept configuration via attributes

### Layout Components (`layouts/`)

Page structure and common UI elements.

**Examples:** ApplicationLayout, NavigationComponent, MailerLayout

**Characteristics:**
- Define page structure
- Compose multiple smaller components
- Handle overall page layout

### Page Components (`pages/`)

Complete page views.

**Examples:** HomePageComponent, DashboardComponent

**Characteristics:**
- Represent entire pages
- Compose multiple components
- Pass data from controllers

### Form Components (`forms/`)

Interactive forms with validation.

**Examples:** LoginFormComponent

**Characteristics:**
- Usually stateful
- Include validation logic
- Handle CSRF tokens
- Integrate with Stimulus

---

## Controller Integration

### Basic Pattern

```crystal
class MyController < ApplicationController
  def index
    # Build page component
    page = Components::Pages::MyPageComponent.new(
      user: current_user,
      data: some_data
    )

    # Wrap in layout
    layout = Components::Layouts::ApplicationLayout.new(
      title: "Page Title",
      content: page.render,
      current_path: request.path,
      logged_in: logged_in?.to_s,
      user_email: get_current_user.try(&.email),
      flash_success: flash[:success]?,
      flash_error: flash[:danger]?,
      flash_info: flash[:info]?
    )

    # Render HTML
    context.response.content_type = "text/html"
    context.response.print layout.render
  end
end
```

---

## Testing Components

Components are fully testable without a browser:

```crystal
require "../component_spec_helper"
require "../../../src/views/components/shared/button_component"

describe Components::Shared::ButtonComponent do
  it "renders button with data attributes" do
    button = Components::Shared::ButtonComponent.new(
      label: "Click Me",
      variant: "primary"
    )

    rendered = button.render

    rendered.should contain("data-component=\"button\"")
    rendered.should contain("data-variant=\"primary\"")
    rendered.should contain("Click Me")
  end
end
```

---

## Additional Resources

### Within This Project

- **Component Documentation:** `src/views/components/CLAUDE.md`
- **Component Examples:** All files in `src/views/components/`
- **Test Examples:** `spec/components/`
- **Migration Documentation:**
  - `ECR_MIGRATION_COMPLETE.md` - Original migration from ECR
  - `RAILS_STRUCTURE_COMPLETE.md` - Rails-style reorganization
  - `MAILER_COMPONENT_COMPLETE.md` - Email components

### Asset Pipeline Library

- **Library:** `lib/asset_pipeline/`
- **Documentation:** `lib/asset_pipeline/CLAUDE.md`
- **GitHub:** https://github.com/amberframework/asset_pipeline
- **Examples:** `lib/asset_pipeline/src/components/examples/`

### Crystal/Amber Resources

- **Amber Framework:** https://amberframework.org
- **Crystal Language:** https://crystal-lang.org
- **Crystal Docs:** https://crystal-lang.org/api

---

## Best Practices

### ✅ DO

- **Use data attributes** - Every component needs identifying attributes
- **Follow naming conventions** - kebab-case for attributes, snake_case for files
- **Keep components small** - Single responsibility principle
- **Write tests** - Test all rendering paths
- **Use semantic HTML** - Choose appropriate elements
- **Document attributes** - Comment what each attribute does

### ❌ DON'T

- **Don't skip data attributes** - They're required for consistency
- **Don't hardcode values** - Use attributes for configuration
- **Don't use HTML strings** - Use Elements classes when possible
- **Don't access database** - Components receive data via attributes
- **Don't use global state** - Components should be pure functions

---

## Debugging Tips

### Finding Components in DOM

```javascript
// Find by component name
document.querySelector('[data-component="button"]')

// Find by variant
document.querySelector('[data-component="button"][data-variant="primary"]')

// Find by component ID
document.querySelector('[data-component-id="submit-button"]')

// Find all of a type
document.querySelectorAll('[data-component="card"]')
```

### Viewing Component Hierarchy

In browser DevTools, search for `data-component` to see all components on the page.

---

## Migration Notes

This application was fully migrated from ECR templates to components:

- **Start Date:** 2025-10-10
- **Components Created:** 12
- **Tests Written:** 263
- **ECR Templates Remaining:** 0 (100% component-based)

See migration documentation files in project root for details.

---

**Last Updated:** 2025-10-10
**Convention Version:** 1.0
**Component Count:** 12
**Test Coverage:** 100%
