# Asset Pipeline View Migration Plan

**Date:** 2025-10-10
**Status:** 🎯 Planning Complete - Ready for Implementation

---

## Overview

This document outlines the plan to migrate Amber ECR template views to Asset Pipeline's testable component system.

### Why Migrate?

1. **Testability** - Components are Crystal classes that can be tested in isolation
2. **Type Safety** - Full compile-time type checking for views
3. **Reusability** - Component-based architecture promotes code reuse
4. **Performance** - Automatic caching for stateless components
5. **Maintainability** - CSS introspection and structured component hierarchy

---

## Component System Architecture

### Base Component Types

**StatelessComponent** (`Components::StatelessComponent`)
- Pure functions that render HTML based on attributes
- Automatically cached based on attribute hash
- No internal state - same inputs always produce same output
- Perfect for: buttons, cards, layouts, static content

**StatefulComponent** (`Components::StatefulComponent`)
- Manages client-side state with JavaScript
- Tracks state changes and re-renders
- Can define action methods that modify state
- Perfect for: forms, interactive widgets, live search

### Component Patterns

```crystal
class MyComponent < Components::StatelessComponent
  def render_content : String
    # Access attributes via @attributes hash
    title = @attributes["title"]? || "Default"

    # Use HTML elements from Components::Elements
    div = Components::Elements::Div.new(class: "my-component")
    div << title

    # Add children if provided
    @children.each do |child|
      case child
      when Components::Component
        div << child.render
      when Components::Elements::HTMLElement
        div << child
      when String
        div << child
      end
    end

    div.render
  end

  # For testing
  def css_selector : String
    ".my-component"
  end
end
```

---

## Current View Inventory

### Views to Migrate

1. **Layouts** (1 file)
   - `src/views/layouts/application.ecr` → Layout component

2. **Public Pages** (2 files)
   - `src/views/public/home/index.ecr` → HomePageComponent
   - `src/views/public/session/new.ecr` → LoginFormComponent

3. **Authenticated Pages** (1 file)
   - `src/views/authenticated/dashboard/index.ecr` → DashboardComponent

4. **Partials** (2 files)
   - `src/views/layouts/_nav.ecr` → NavigationComponent
   - `src/views/layouts/_session.ecr` → SessionInfoComponent

---

## Migration Strategy

### Phase 1: Create Component Infrastructure

**Directory Structure:**
```
src/
  components/
    layouts/
      application_layout.cr
      navigation_component.cr
      session_info_component.cr
      flash_message_component.cr
    pages/
      home_page_component.cr
      dashboard_component.cr
    forms/
      login_form_component.cr
    shared/
      button_component.cr
      card_component.cr
      stat_card_component.cr
      icon_component.cr
```

**Test Structure:**
```
spec/
  components/
    layouts/
      application_layout_spec.cr
      navigation_component_spec.cr
      flash_message_component_spec.cr
    pages/
      home_page_component_spec.cr
      dashboard_component_spec.cr
    forms/
      login_form_component_spec.cr
```

### Phase 2: Build Shared Components (Foundation)

These reusable components will be used by page-level components:

1. **ButtonComponent** (Stateless)
   - Variants: primary, secondary, danger
   - Sizes: small, medium, large
   - Icons support
   - Disabled state

2. **CardComponent** (Stateless)
   - Title, subtitle, content slots
   - Optional image
   - Shadow variants

3. **StatCardComponent** (Stateless)
   - Icon, title, value
   - Trend indicator (up/down)
   - Background color variants

4. **IconComponent** (Stateless)
   - SVG icon wrapper
   - Size variants
   - Color variants

5. **FlashMessageComponent** (Stateless)
   - Types: success, error, info, warning
   - Auto-styling based on type
   - Icon integration

### Phase 3: Build Layout Components

1. **NavigationComponent** (Stateless)
   - Logo and branding
   - Navigation links
   - Session info integration
   - Mobile menu toggle

2. **SessionInfoComponent** (Stateless)
   - Logged-in state display
   - User email/info
   - Logout button
   - Login/signup links when not authenticated

3. **ApplicationLayout** (Stateless)
   - HTML head (meta tags, CSS, JS)
   - Navigation component
   - Flash messages
   - Main content slot
   - Footer (if needed)

### Phase 4: Build Page Components

1. **LoginFormComponent** (Stateful)
   - Email/password fields
   - CSRF token integration
   - Stimulus controller data attributes
   - Validation state
   - Remember me checkbox
   - Forgot password link

2. **HomePageComponent** (Stateless)
   - Hero section
   - Features section
   - Resources section
   - Dynamic CTA based on auth state

3. **DashboardComponent** (Stateless)
   - Header with action button
   - Stat cards grid (uses StatCardComponent)
   - Recent activity timeline
   - Quick actions grid

### Phase 5: Update Controllers

Modify controllers to render components instead of ECR templates:

```crystal
class HomeController < ApplicationController
  def index
    # Old way:
    # render("index.ecr")

    # New way:
    component = Components::Pages::HomePageComponent.new(
      logged_in: logged_in?,
      current_user: current_user
    )
    render html: component.render
  end
end
```

### Phase 6: Create Layout Rendering Helper

Create helper to integrate components with Amber's layout system:

```crystal
# src/helpers/component_helper.cr
module ComponentHelper
  def render_with_layout(component : Components::Component, layout : Components::Component? = nil)
    layout ||= Components::Layouts::ApplicationLayout.new

    # Set content slot in layout
    if layout.responds_to?(:content=)
      layout.content = component.render
    end

    layout.render
  end

  def render_component(component : Components::Component)
    render html: component.render
  end
end
```

---

## Component Specifications

### Shared Components

#### ButtonComponent

**Type:** Stateless
**Location:** `src/components/shared/button_component.cr`

**Attributes:**
- `label` (String) - Button text
- `variant` (String) - "primary", "secondary", "danger" (default: "primary")
- `size` (String) - "small", "medium", "large" (default: "medium")
- `type` (String) - "button", "submit" (default: "button")
- `disabled` (String) - "true" or nil
- `icon` (String?) - Optional icon/emoji
- `href` (String?) - If provided, renders as link styled as button
- `class` (String?) - Additional CSS classes

**CSS Classes:**
- Base: `btn`
- Variants: `btn-primary`, `btn-secondary`, `btn-danger`
- Sizes: `btn-small`, `btn-medium`, `btn-large`
- State: `disabled`

**Tests:**
- Renders with default settings
- Applies variant classes correctly
- Applies size classes correctly
- Renders icon when provided
- Renders as link when href provided
- Applies disabled state

---

#### FlashMessageComponent

**Type:** Stateless
**Location:** `src/components/shared/flash_message_component.cr`

**Attributes:**
- `type` (String) - "success", "error", "info", "warning"
- `message` (String) - Flash message content

**CSS Classes:**
- Base: `flash-message`
- Types: `flash-success`, `flash-error`, `flash-info`, `flash-warning`

**Behavior:**
- Auto-selects icon based on type
- Auto-selects color scheme based on type
- Renders with appropriate ARIA attributes

**Tests:**
- Renders success messages with green styling
- Renders error messages with red styling
- Renders info messages with blue styling
- Renders warning messages with yellow styling
- Includes correct icon for each type
- Contains message text

---

#### StatCardComponent

**Type:** Stateless
**Location:** `src/components/shared/stat_card_component.cr`

**Attributes:**
- `title` (String) - Stat label (e.g., "Total Users")
- `value` (String) - Stat value (e.g., "1,247")
- `icon` (String) - SVG path data or icon class
- `trend` (String?) - "up" or "down"
- `trend_value` (String?) - Percentage (e.g., "12%")
- `bg_color` (String) - Background color for icon (default: "indigo")

**CSS Classes:**
- Base: `stat-card`
- Icon wrapper: `stat-icon bg-{color}-500`
- Trend: `trend-up`, `trend-down`

**Tests:**
- Renders title and value
- Displays icon with correct background
- Shows upward trend with green color
- Shows downward trend with red color
- Handles missing trend gracefully

---

### Layout Components

#### NavigationComponent

**Type:** Stateless
**Location:** `src/components/layouts/navigation_component.cr`

**Attributes:**
- `current_path` (String) - Current request path for active link styling
- `logged_in` (Bool) - Whether user is authenticated
- `current_user` (CurrentUser?) - Current user object

**Children:**
- SessionInfoComponent

**CSS Classes:**
- Base: `nav`
- Active link: `nav-link-active`
- Mobile menu: `mobile-menu`

**Tests:**
- Renders logo and branding
- Highlights active navigation link
- Shows session info when logged in
- Shows login link when not logged in
- Includes mobile menu toggle

---

#### ApplicationLayout

**Type:** Stateless
**Location:** `src/components/layouts/application_layout.cr`

**Attributes:**
- `title` (String) - Page title (default: "AgentC App")
- `flash` (Hash(String, String)) - Flash messages
- `content` (String) - Main page content HTML

**Children:**
- NavigationComponent
- FlashMessageComponent (for each flash message)

**Tests:**
- Renders HTML doctype and structure
- Includes CSS and JS assets
- Renders Asset Pipeline import map
- Displays navigation component
- Shows flash messages
- Injects content in main section

---

### Page Components

#### LoginFormComponent

**Type:** Stateful
**Location:** `src/components/forms/login_form_component.cr`

**Attributes:**
- `csrf_token` (String) - CSRF token for form
- `email_value` (String) - Pre-filled email (optional)

**State:**
- `email` (String) - Current email input value
- `password` (String) - Current password input value
- `errors` (Hash) - Validation errors
- `submitting` (Bool) - Form submission state

**Methods:**
- `field_changed(data : JSON::Any)` - Handle input changes
- `validate` - Validate form fields
- `submit` - Handle form submission

**Tests:**
- Renders email and password fields
- Includes CSRF token
- Shows validation errors
- Disables submit button when submitting
- Includes "Remember me" checkbox
- Shows "Forgot password" link
- Pre-fills email when provided

---

#### HomePageComponent

**Type:** Stateless
**Location:** `src/components/pages/home_page_component.cr`

**Attributes:**
- `logged_in` (Bool) - Whether user is authenticated

**Children:**
- Multiple CardComponents for features
- ButtonComponents for CTAs

**Sections:**
1. Hero section with CTA
2. Features grid (4 cards)
3. Resources section (3 cards)

**Tests:**
- Renders hero section with title
- Shows "Get started" CTA when not logged in
- Shows "Go to Dashboard" when logged in
- Displays all 4 feature cards
- Displays all 3 resource cards
- All links are correct

---

#### DashboardComponent

**Type:** Stateless
**Location:** `src/components/pages/dashboard_component.cr`

**Attributes:**
- `current_user` (CurrentUser) - User viewing dashboard

**Children:**
- 4 StatCardComponents
- Activity timeline
- Quick actions grid

**Tests:**
- Renders page title
- Shows "New Project" button
- Displays 4 stat cards
- Renders activity timeline with 3 items
- Shows 3 quick action buttons
- Each quick action has correct icon and label

---

## Integration with Amber

### Controller Pattern

```crystal
class HomeController < ApplicationController
  def index
    component = Components::Pages::HomePageComponent.new(
      logged_in: logged_in?
    )

    layout = Components::Layouts::ApplicationLayout.new(
      title: "Welcome to AgentC",
      flash: flash.to_h,
      content: component.render
    )

    render html: layout.render
  end
end
```

### Accessing Request Context

Components need access to:
- Current user (pass as attribute)
- Flash messages (pass as attribute)
- CSRF tokens (pass as attribute)
- Current path (pass as attribute)

```crystal
# In controller
def login_form
  component = Components::Forms::LoginFormComponent.new(
    csrf_token: csrf_token
  )

  render_with_layout(component, title: "Sign In")
end
```

---

## Testing Strategy

### Component Test Pattern

```crystal
require "../spec_helper"
require "../../src/components/shared/button_component"

describe Components::Shared::ButtonComponent do
  describe "rendering" do
    it "renders a basic button" do
      button = Components::Shared::ButtonComponent.new(label: "Click Me")
      rendered = button.render

      rendered.should contain("<button")
      rendered.should contain("Click Me")
      rendered.should contain("btn btn-primary btn-medium")
    end

    it "applies variant classes" do
      button = Components::Shared::ButtonComponent.new(
        label: "Delete",
        variant: "danger"
      )

      button.render.should contain("btn-danger")
    end
  end

  describe "css_selector" do
    it "returns correct selector" do
      button = Components::Shared::ButtonComponent.new(label: "Test")
      button.css_selector.should eq(".btn.btn-primary.btn-medium")
    end
  end

  describe "caching" do
    it "generates same cache key for same attributes" do
      btn1 = Components::Shared::ButtonComponent.new(label: "Test", variant: "primary")
      btn2 = Components::Shared::ButtonComponent.new(label: "Test", variant: "primary")

      btn1.cache_key.should eq(btn2.cache_key)
    end

    it "generates different cache keys for different attributes" do
      btn1 = Components::Shared::ButtonComponent.new(label: "Test", variant: "primary")
      btn2 = Components::Shared::ButtonComponent.new(label: "Test", variant: "danger")

      btn1.cache_key.should_not eq(btn2.cache_key)
    end
  end
end
```

### Testing Stateful Components

```crystal
describe Components::Forms::LoginFormComponent do
  it "validates email format" do
    form = Components::Forms::LoginFormComponent.new(csrf_token: "test-token")

    # Set invalid email
    form.field_changed(JSON.parse(%{{"field": "email", "value": "invalid"}}))

    errors = form.get_state("errors").try(&.as_h?)
    errors.not_nil!["email"]?.should_not be_nil

    # Set valid email
    form.field_changed(JSON.parse(%{{"field": "email", "value": "test@example.com"}}))

    errors = form.get_state("errors").try(&.as_h?)
    errors.not_nil!["email"]?.should be_nil
  end
end
```

### Integration Tests

Update existing controller specs to verify components render:

```crystal
describe "GET /dashboard" do
  context "when authenticated" do
    it "renders dashboard component" do
      user = create_regular_user
      # ... set up authenticated session ...

      response = get("/dashboard")

      response.status_code.should eq(200)
      response.body.should contain("Dashboard")
      response.body.should contain("Total Users")
      response.body.should contain("stat-card")
    end
  end
end
```

---

## Implementation Checklist

### Shared Components
- [ ] Create `src/components/shared/button_component.cr`
- [ ] Create `src/components/shared/card_component.cr`
- [ ] Create `src/components/shared/stat_card_component.cr`
- [ ] Create `src/components/shared/icon_component.cr`
- [ ] Create `src/components/shared/flash_message_component.cr`
- [ ] Write tests for all shared components

### Layout Components
- [ ] Create `src/components/layouts/navigation_component.cr`
- [ ] Create `src/components/layouts/session_info_component.cr`
- [ ] Create `src/components/layouts/application_layout.cr`
- [ ] Write tests for all layout components

### Page Components
- [ ] Create `src/components/forms/login_form_component.cr`
- [ ] Create `src/components/pages/home_page_component.cr`
- [ ] Create `src/components/pages/dashboard_component.cr`
- [ ] Write tests for all page components

### Controller Integration
- [ ] Update `HomeController` to use `HomePageComponent`
- [ ] Update `SessionController#new` to use `LoginFormComponent`
- [ ] Update `DashboardController` to use `DashboardComponent`
- [ ] Create component rendering helpers

### Validation
- [ ] Run component tests (`crystal spec spec/components/`)
- [ ] Run integration tests (`crystal spec spec/controllers/`)
- [ ] Manual testing of all pages
- [ ] Verify styling matches original designs
- [ ] Check mobile responsiveness

### Cleanup
- [ ] Archive old ECR templates (move to `src/views/legacy/`)
- [ ] Update documentation
- [ ] Remove unused ECR rendering code

---

## Benefits After Migration

1. **Type Safety**
   - Compile-time checking of all view logic
   - No more runtime template errors
   - Intellisense/autocomplete in editors

2. **Testability**
   - Test components in isolation
   - Verify CSS selectors for Capybara/Selenium tests
   - Mock component dependencies easily

3. **Performance**
   - Automatic caching for stateless components
   - No template parsing at runtime
   - Smaller memory footprint

4. **Maintainability**
   - Clear component hierarchy
   - Reusable components across pages
   - Easy to refactor and update

5. **Developer Experience**
   - Crystal syntax for views (no ERB/ECR)
   - Better IDE support
   - Easier debugging with stack traces

---

## Migration Timeline

1. **Phase 1-2** (Shared components) - Build foundation
2. **Phase 3** (Layout components) - Create layout structure
3. **Phase 4** (Page components) - Migrate pages one by one
4. **Phase 5** (Controller updates) - Wire up components
5. **Phase 6** (Testing & validation) - Ensure everything works
6. **Phase 7** (Cleanup) - Remove old templates

**Total Components:** ~13
**Estimated Lines of Code:** ~2,000-3,000 lines (components + tests)

---

**Last Updated:** 2025-10-10
**Next Step:** Begin Phase 1 - Create component infrastructure and shared components
