---
name: asset-pipeline-components
description: Comprehensive guide for working with AssetPipeline view components in src/views/**
---

# Building Views With The Asset Pipeline

This library and component system works like the widgets from Flutter in that we have stateful and stateless components.

Stateless components can be easily cached and rendered at the app boot time.
Stateful components can be rendered once and then broadcast updates to the UI when the state changes, and a StimulusJS controller can be associated with the component to handle it's interactivity.


## 🎯 Quick Start

**Creating a new component? Follow this checklist:**

1. ✅ Choose component type: `StatelessComponent` (pure, cached) or `StatefulComponent` (interactive)
2. ✅ Create file: `src/views/components/{category}/{name}_component.cr`
3. ✅ Add `data-component="name"` attribute to outermost HTML element
4. ✅ Extract attributes with defaults at start of `render_content`
5. ✅ Escape user content with `escape_html()`
6. ✅ Create test file: `spec/components/{category}/{name}_component_spec.cr`

**Most common task patterns:**
- **Creating button/card/icon** → Use `StatelessComponent`, add data attributes, extract props
- **Creating form/widget** → Use `StatefulComponent`, manage state, validate inputs
- **Composing page** → Combine smaller components, pass data from controller
- **Testing component** → Check rendering, data attributes, cache keys

---

## 📚 Table of Contents

1. [Element & Attribute Reference](#element--attribute-reference)
2. [Core Architecture](#core-architecture)
3. [Component Types](#component-types)
4. [Critical Conventions](#critical-conventions)
5. [Component Creation Guide](#component-creation-guide)
6. [Common Patterns](#common-patterns)
7. [Controller Integration](#controller-integration)
8. [Testing Guide](#testing-guide)
9. [Common Gotchas](#common-gotchas)
10. [Quick Reference](#quick-reference)

---

## Element & Attribute Reference

### 🔍 Need to Look Up an HTML Element?

**What's in the reference:**
- All 87 HTML5 elements with examples
- Complete attribute listings for every element
- Constructor patterns for all element types
- Global attributes reference (work on all elements)
- Form-specific attributes and validation
- Event handler attributes
- Input type constructors (17 types)
- Security and escaping guidelines
- Common element patterns (forms, tables, navigation, cards)

### Quick Element Lookup

**Most commonly used elements:**

**Layout & Structure:**
- `Elements::Div` - Generic container (most common)
- `Elements::Header`, `Elements::Footer`, `Elements::Main` - Page structure
- `Elements::Section`, `Elements::Article`, `Elements::Aside` - Content sections
- `Elements::Nav` - Navigation container

**Text:**
- `Elements::H1` through `Elements::H6` - Headings
- `Elements::P` - Paragraphs
- `Elements::Span` - Inline container
- `Elements::A` - Links
- `Elements::Strong`, `Elements::Em` - Emphasis
- `Elements::Code`, `Elements::Pre` - Code display

**Forms:**
- `Elements::Form` - Form container
- `Elements::Input` - Input fields (17 types: text, email, password, etc.)
- `Elements::Button` - Buttons
- `Elements::Select`, `Elements::Option` - Dropdowns
- `Elements::Textarea` - Multi-line text
- `Elements::Label` - Form labels

**Tables:**
- `Elements::Table` - Table container
- `Elements::Thead`, `Elements::Tbody`, `Elements::Tfoot` - Table sections
- `Elements::Tr`, `Elements::Th`, `Elements::Td` - Rows and cells

**Media:**
- `Elements::Img` - Images
- `Elements::Video`, `Elements::Audio` - Media players
- `Elements::Svg` - Vector graphics
- `Elements::Canvas` - Graphics canvas

**Usage Example:**
```crystal
# Look up Button element in reference for all attributes
# Then use in your component:
button = Elements::Button.new(
  type: "submit",
  class: "btn btn-primary",
  disabled: false
) { "Submit Form" }

html << button.render
```

**When building components**, you'll typically use:
1. String.build with HTML strings (current practice) ← Most common
2. Element classes directly (less common, but available)
3. Mix of both approaches

**See the element reference for:**
- Complete constructor signatures
- All available attributes per element
- Validation rules and constraints
- Security considerations (HTML escaping)

---

## Core Architecture

### The Paradigm Shift

**Old Way (String Templates):**
```erb
<!-- views/home.ecr -->
<div class="card">
  <h2><%= title %></h2>
  <p><%= description %></p>
</div>
```

**New Way (Component Objects):**
```crystal
class CardComponent < StatelessComponent
  def render_content : String
    title = @attributes["title"]? || "Card"
    description = @attributes["description"]? || ""

    String.build do |html|
      html << "<div data-component=\"card\" class=\"card\">"
      html << "  <h2>#{title}</h2>"
      html << "  <p>#{description}</p>"
      html << "</div>"
    end
  end
end
```

**Why components?**
- Type safety (Crystal compile-time checks)
- Reusability (compose large from small)
- Testability (unit test each component)
- Performance (automatic caching)
- Maintainability (clear boundaries)

### Three-Layer Architecture

```
┌─────────────────────────────────────────┐
│ Pages (Full Views)                       │
│ - HomePageComponent                      │
│ - DashboardComponent                     │
└──────────────┬──────────────────────────┘
               │ composed of
┌──────────────▼──────────────────────────┐
│ Components (Reusable UI Units)           │
│ - ButtonComponent                        │
│ - CardComponent                          │
│ - NavigationComponent                    │
└──────────────┬──────────────────────────┘
               │ built from
┌──────────────▼──────────────────────────┐
│ Elements (HTML5 Building Blocks)         │
│ - Div, Button, Input, Form, etc.        │
│ - 100+ typed element classes             │
└─────────────────────────────────────────┘
```

---

## Component Types

### Stateless Components (USE THESE WHEN POSSIBLE)

**What**: Pure functions - same inputs always produce same outputs
**Performance**: Automatically cached (500x faster after first render)
**Use for**: Buttons, cards, icons, layouts, static content

```crystal
class ButtonComponent < StatelessComponent
  def render_content : String
    label = @attributes["label"]? || "Button"
    variant = @attributes["variant"]? || "primary"
    size = @attributes["size"]? || "medium"
    disabled = @attributes["disabled"]? == "true"

    String.build do |html|
      html << "<button "
      html << "data-component=\"button\" "
      html << "data-variant=\"#{variant}\" "
      html << "data-size=\"#{size}\" "
      html << "class=\"btn btn-#{variant} btn-#{size}\" "
      html << "disabled " if disabled
      html << "type=\"button\">"
      html << "  #{escape_html(label)}"
      html << "</button>"
    end
  end

  def css_selector : String
    "[data-component='button']"
  end
end

# Usage:
button = ButtonComponent.new(label: "Save", variant: "primary")
html = button.render  # Cached after first call!
```

### Stateful Components (USE WHEN NEEDED)

**What**: Manage client-side state and user interactions
**Performance**: Not cached by default
**Use for**: Forms, live search, counters, interactive widgets

```crystal
class LoginFormComponent < StatefulComponent
  # Initialize state when component created
  protected def initialize_state
    set_state("email", @attributes["email_value"]? || "")
    set_state("password", "")
    set_state("errors", Hash(String, JSON::Any).new)
    set_state("submitting", false)
  end

  # Validation logic
  def validate : Hash(String, JSON::Any)
    errors = Hash(String, JSON::Any).new
    email = get_state("email").try(&.as_s?) || ""

    if email.empty?
      errors["email"] = JSON::Any.new("Email is required")
    elsif !email.matches?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      errors["email"] = JSON::Any.new("Invalid email format")
    end

    set_state("errors", errors)
    errors
  end

  def render_content : String
    email = get_state("email").try(&.as_s?) || ""
    errors = get_state("errors").try(&.as_h?) || {}
    error_msg = @attributes["error"]?

    String.build do |html|
      html << "<form data-component=\"login-form\" "
      html << "data-controller=\"login-form\" "
      html << "action=\"/login\" method=\"post\">"

      # Error display
      if error_msg
        html << "<div class=\"error-message\">#{escape_html(error_msg)}</div>"
      end

      # Email field
      html << "<input type=\"email\" "
      html << "name=\"email\" "
      html << "value=\"#{escape_html(email)}\" "
      html << "data-action=\"blur->login-form#validateEmail\" "
      html << "required>"

      if email_error = errors["email"]?
        html << "<span class=\"error\">#{email_error}</span>"
      end

      html << "</form>"
    end
  end
end
```

---

## Critical Conventions

### ⚠️ DATA ATTRIBUTES (REQUIRED!)

**Every component MUST include `data-component` on its outermost element.**

```crystal
# ❌ BAD - No data attribute
html << "<button class=\"btn\">#{label}</button>"

# ✅ GOOD - Has data attribute
html << "<button data-component=\"button\" class=\"btn\">#{label}</button>"
```

**Why this matters:**
1. **Debugging**: Know which component rendered which HTML
2. **Testing**: Stable selectors that don't break with CSS changes
3. **JavaScript**: Easy DOM queries (`querySelector('[data-component="button"]')`)
4. **Stimulus**: Natural pairing with controllers
5. **Component boundaries**: Clear ownership in the DOM

**Additional data attributes to include:**
- `data-variant="primary"` - For variants
- `data-state="loading"` - For state (idle, loading, error, success)
- `data-size="large"` - For sizing options
- `data-testid="submit-btn"` - For test targeting

### File Organization

```
src/views/
  components/
    shared/              # Reusable UI components
      button_component.cr
      icon_component.cr
      card_component.cr
      flash_message_component.cr
    layouts/             # Page structure
      application_layout.cr
      navigation_component.cr
      session_info_component.cr
    pages/               # Full page views
      home_page_component.cr
      dashboard_component.cr
    forms/               # Form components
      login_form_component.cr
    CLAUDE.md            # Component documentation

spec/components/        # Mirror src structure
  shared/
    button_component_spec.cr
  component_spec_helper.cr
```

### Naming Conventions

**Files:** `component_name_component.cr` (snake_case)
**Classes:** `ComponentNameComponent` (PascalCase)
**Namespaces:** `Components::{Category}::{Name}Component`

```crystal
# File: src/views/components/shared/button_component.cr
module Components
  module Shared
    class ButtonComponent < StatelessComponent
      # ...
    end
  end
end
```

---

## Component Creation Guide

### Step-by-Step: Create a New Component

**Example: Creating a StatCard component**

#### Step 1: Create the file

```bash
# File: src/views/components/shared/stat_card_component.cr
```

#### Step 2: Define the class

```crystal
require "../../stateless_component"

module Components
  module Shared
    class StatCardComponent < StatelessComponent

    end
  end
end
```

#### Step 3: Implement `render_content`

```crystal
def render_content : String
  # Extract attributes with defaults
  title = @attributes["title"]? || "Stat"
  value = @attributes["value"]? || "0"
  trend = @attributes["trend"]? || "neutral"  # up, down, neutral
  icon_path = @attributes["icon_path"]?

  # Build HTML
  String.build do |html|
    html << "<div data-component=\"stat-card\" "
    html << "data-trend=\"#{trend}\" "
    html << "class=\"stat-card stat-card--#{trend}\">"

    # Icon (if provided)
    if icon_path
      icon = IconComponent.new(path: icon_path, size: "h-8 w-8")
      html << icon.render
    end

    # Content
    html << "  <div class=\"stat-card__content\">"
    html << "    <h3 class=\"stat-card__title\">#{escape_html(title)}</h3>"
    html << "    <p class=\"stat-card__value\">#{escape_html(value)}</p>"
    html << "  </div>"

    # Trend indicator
    html << "  <span class=\"stat-card__trend stat-card__trend--#{trend}\">"
    html << trend_icon(trend)
    html << "  </span>"

    html << "</div>"
  end
end

private def trend_icon(trend : String) : String
  case trend
  when "up"   then "↑"
  when "down" then "↓"
  else "—"
  end
end
```

#### Step 4: Implement `css_selector`

```crystal
def css_selector : String
  "[data-component='stat-card']"
end
```

#### Step 5: Create test file

```bash
# File: spec/components/shared/stat_card_component_spec.cr
```

```crystal
require "../component_spec_helper"
require "../../../src/views/components/shared/stat_card_component"

describe Components::Shared::StatCardComponent do
  describe "rendering" do
    it "renders with default attributes" do
      card = Components::Shared::StatCardComponent.new(
        title: "Users",
        value: "1,234"
      )

      rendered = card.render
      rendered.should contain("Users")
      rendered.should contain("1,234")
      rendered.should contain("data-component=\"stat-card\"")
    end

    it "applies trend styling" do
      card = Components::Shared::StatCardComponent.new(
        title: "Revenue",
        value: "$50K",
        trend: "up"
      )

      rendered = card.render
      rendered.should contain("data-trend=\"up\"")
      rendered.should contain("↑")
    end
  end

  describe "data attributes" do
    it "includes component identifier" do
      card = Components::Shared::StatCardComponent.new(title: "Test", value: "0")
      card.render.should contain("data-component=\"stat-card\"")
    end
  end
end
```

#### Step 6: Use in a controller

```crystal
class DashboardController < ApplicationController
  def index
    # Create stat cards
    user_card = Components::Shared::StatCardComponent.new(
      title: "Total Users",
      value: User.count.to_s,
      trend: "up"
    )

    revenue_card = Components::Shared::StatCardComponent.new(
      title: "Revenue",
      value: "$#{calculate_revenue}",
      trend: calculate_trend
    )

    # Build dashboard page
    page = Components::Pages::DashboardComponent.new(
      user_card: user_card.render,
      revenue_card: revenue_card.render
    )

    render_component(page, "Dashboard")
  end
end
```

---

## Common Patterns

### Pattern 1: Attribute Extraction

**Always extract attributes at the start with defaults:**

```crystal
def render_content : String
  # Extract ALL attributes upfront
  title = @attributes["title"]? || "Default Title"
  variant = @attributes["variant"]? || "primary"
  size = @attributes["size"]? || "medium"
  show_icon = @attributes["show_icon"]? == "true"
  disabled = @attributes["disabled"]? == "true"

  # Then build HTML
  # ...
end
```

### Pattern 2: Composing Components

**Build larger components from smaller reusable pieces:**

```crystal
def render_content : String
  title = @attributes["title"]? || "Card"
  description = @attributes["description"]? || ""
  button_label = @attributes["button_label"]? || "Action"

  # Create child components
  icon = Shared::IconComponent.new(
    path: "M5 13l4 4L19 7",
    size: "h-6 w-6"
  )

  button = Shared::ButtonComponent.new(
    label: button_label,
    variant: "primary"
  )

  # Combine them
  String.build do |html|
    html << "<div data-component=\"card\" class=\"card\">"
    html << icon.render
    html << "  <h2>#{escape_html(title)}</h2>"
    html << "  <p>#{escape_html(description)}</p>"
    html << button.render
    html << "</div>"
  end
end
```

### Pattern 3: Conditional Rendering

```crystal
def render_content : String
  show_header = @attributes["show_header"]? == "true"
  error = @attributes["error"]?
  items = @attributes["items"]? || "[]"

  String.build do |html|
    html << "<div data-component=\"list\">"

    # Conditional header
    if show_header
      html << "<header class=\"list__header\">"
      html << "  <h2>Items</h2>"
      html << "</header>"
    end

    # Error state
    if error
      html << "<div class=\"list__error\">"
      html << "  #{escape_html(error)}"
      html << "</div>"
    end

    # Empty state
    if items == "[]"
      html << "<div class=\"list__empty\">"
      html << "  No items found"
      html << "</div>"
    else
      html << render_items(items)
    end

    html << "</div>"
  end
end
```

### Pattern 4: Handling Children

```crystal
def render_content : String
  String.build do |html|
    html << "<div data-component=\"container\">"

    # Render all children
    @children.each do |child|
      case child
      when Component
        html << child.render
      when Elements::HTMLElement
        html << child.render
      when String
        html << escape_html(child)  # IMPORTANT: Escape strings!
      end
    end

    html << "</div>"
  end
end
```

### Pattern 5: Variant Styling

```crystal
def render_content : String
  variant = @attributes["variant"]? || "default"
  size = @attributes["size"]? || "medium"

  # Build CSS classes based on variants
  classes = ["component"]
  classes << "component--#{variant}"
  classes << "component--#{size}"
  classes << "component--disabled" if @attributes["disabled"]? == "true"

  String.build do |html|
    html << "<div "
    html << "data-component=\"component\" "
    html << "data-variant=\"#{variant}\" "
    html << "class=\"#{classes.join(" ")}\">"
    html << "  Content here"
    html << "</div>"
  end
end
```

---

## Controller Integration

### Basic Pattern

```crystal
class HomeController < ApplicationController
  def index
    # Build page component with data
    page = Components::Pages::HomePageComponent.new(
      logged_in: logged_in?.to_s,
      current_user_email: current_user.try(&.email) || ""
    )

    # Render directly
    render html: page.render
  end
end
```

### With Layout Wrapper

```crystal
class DashboardController < ApplicationController
  def index
    # Build page content
    page = Components::Pages::DashboardComponent.new(
      user_name: current_user.name,
      stats: fetch_dashboard_stats
    )

    # Wrap in application layout
    layout = Components::Layouts::ApplicationLayout.new(
      title: "Dashboard",
      content: page.render,
      current_path: request.path,
      logged_in: logged_in?.to_s,
      user_email: current_user.email,
      flash_success: flash[:success]?,
      flash_error: flash[:danger]?
    )

    # Send to browser
    context.response.content_type = "text/html"
    context.response.print layout.render
  end
end
```

### Helper Method Pattern

```crystal
abstract class ApplicationController < Amber::Controller::Base
  # Reusable rendering helper
  def render_component(component : Component, title = "App")
    layout = Components::Layouts::ApplicationLayout.new(
      title: title,
      content: component.render,
      current_path: request.path,
      logged_in: logged_in?.to_s,
      user_email: current_user.try(&.email),
      flash_success: flash[:success]?,
      flash_error: flash[:danger]?
    )

    context.response.content_type = "text/html"
    context.response.print layout.render
  end
end

# Usage in any controller:
class DashboardController < ApplicationController
  def index
    page = Components::Pages::DashboardComponent.new(
      user: current_user
    )
    render_component(page, "Dashboard")
  end
end
```

### Data Flow Best Practice

**❌ BAD - Database access in component:**
```crystal
class UserProfileComponent < StatelessComponent
  def render_content : String
    user = User.find(@attributes["user_id"])  # Don't do this!
    "<div>#{user.name}</div>"
  end
end
```

**✅ GOOD - Pass data from controller:**
```crystal
# Controller
def show
  user = User.find(params["id"])
  profile = UserProfileComponent.new(
    user_name: user.name,
    user_email: user.email,
    user_bio: user.bio
  )
  render_component(profile, user.name)
end

# Component
class UserProfileComponent < StatelessComponent
  def render_content : String
    name = @attributes["user_name"]?
    email = @attributes["user_email"]?

    String.build do |html|
      html << "<div data-component=\"user-profile\">"
      html << "  <h1>#{escape_html(name)}</h1>"
      html << "  <p>#{escape_html(email)}</p>"
      html << "</div>"
    end
  end
end
```

---

## Testing Guide

### Test File Structure

```crystal
require "../component_spec_helper"
require "../../../src/views/components/shared/button_component"

describe Components::Shared::ButtonComponent do
  describe "initialization" do
    it "creates component with attributes" do
      button = Components::Shared::ButtonComponent.new(
        label: "Click Me",
        variant: "primary"
      )

      button.should_not be_nil
    end
  end

  describe "rendering" do
    it "renders button with label" do
      button = Components::Shared::ButtonComponent.new(label: "Test")
      rendered = button.render

      rendered.should contain("<button")
      rendered.should contain("Test")
      rendered.should contain("</button>")
    end

    it "applies variant classes" do
      button = Components::Shared::ButtonComponent.new(
        label: "Delete",
        variant: "danger"
      )

      button.render.should contain("btn-danger")
    end

    it "handles disabled state" do
      button = Components::Shared::ButtonComponent.new(
        label: "Save",
        disabled: "true"
      )

      button.render.should contain("disabled")
    end
  end

  describe "data attributes" do
    it "includes component identifier" do
      button = Components::Shared::ButtonComponent.new(label: "Test")
      button.render.should contain("data-component=\"button\"")
    end

    it "includes variant data attribute" do
      button = Components::Shared::ButtonComponent.new(
        label: "Test",
        variant: "secondary"
      )

      button.render.should contain("data-variant=\"secondary\"")
    end
  end

  describe "CSS selectors" do
    it "provides correct selector" do
      button = Components::Shared::ButtonComponent.new(label: "Test")
      button.css_selector.should eq("[data-component='button']")
    end
  end

  describe "caching" do
    it "generates consistent cache keys for identical components" do
      btn1 = Components::Shared::ButtonComponent.new(label: "Test")
      btn2 = Components::Shared::ButtonComponent.new(label: "Test")

      btn1.cache_key.should eq(btn2.cache_key)
    end

    it "generates different cache keys for different attributes" do
      btn1 = Components::Shared::ButtonComponent.new(label: "Test")
      btn2 = Components::Shared::ButtonComponent.new(label: "Different")

      btn1.cache_key.should_not eq(btn2.cache_key)
    end
  end
end
```

### Testing Stateful Components

```crystal
describe Components::Forms::LoginFormComponent do
  describe "state management" do
    it "initializes with default state" do
      form = Components::Forms::LoginFormComponent.new

      form.get_state("email").try(&.as_s?).should eq("")
      form.get_state("submitting").try(&.as_bool?).should eq(false)
    end

    it "updates state" do
      form = Components::Forms::LoginFormComponent.new
      form.set_state("email", "test@example.com")

      form.get_state("email").try(&.as_s?).should eq("test@example.com")
    end
  end

  describe "validation" do
    it "validates email format" do
      form = Components::Forms::LoginFormComponent.new
      form.set_state("email", "invalid")

      errors = form.validate
      errors.should have_key("email")
    end

    it "passes validation with valid email" do
      form = Components::Forms::LoginFormComponent.new
      form.set_state("email", "valid@example.com")

      errors = form.validate
      errors.should be_empty
    end
  end
end
```

---

## Common Gotchas

### 🚨 Gotcha 1: Missing Data Attributes

**Problem:** Component HTML doesn't include `data-component` attribute
**Impact:** Hard to debug, test, and integrate with JavaScript
**Solution:** ALWAYS add data attributes to outermost element

```crystal
# ❌ BAD
html << "<button class=\"btn\">#{label}</button>"

# ✅ GOOD
html << "<button data-component=\"button\" "
html << "data-variant=\"#{variant}\" "
html << "class=\"btn\">#{label}</button>"
```

### 🚨 Gotcha 2: Not Escaping User Content (XSS VULNERABILITY!)

**Problem:** User input rendered directly causes XSS attacks
**Impact:** Security vulnerability
**Solution:** Use `escape_html()` for all user-provided content

```crystal
# ❌ DANGEROUS - XSS vulnerability
user_input = params["name"]
html << "<div>#{user_input}</div>"

# ✅ SAFE - Escaped
user_input = params["name"]
html << "<div>#{escape_html(user_input)}</div>"
```

### 🚨 Gotcha 3: Hardcoded Values

**Problem:** Component not reusable or configurable
**Impact:** Have to create duplicate components
**Solution:** Accept configuration via attributes

```crystal
# ❌ BAD - Hardcoded
def render_content : String
  "<button class=\"btn btn-primary\">Click Me</button>"
end

# ✅ GOOD - Configurable
def render_content : String
  label = @attributes["label"]? || "Button"
  variant = @attributes["variant"]? || "primary"

  "<button class=\"btn btn-#{variant}\">#{escape_html(label)}</button>"
end
```

### 🚨 Gotcha 4: Database Access in Components

**Problem:** Components become slow, untestable, and violate separation
**Impact:** Performance, coupling, testing difficulty
**Solution:** Pass data from controller via attributes

```crystal
# ❌ BAD - Database access
def render_content : String
  user = User.find(user_id)  # Don't!
  "<div>#{user.name}</div>"
end

# ✅ GOOD - Data passed in
# Controller:
user = User.find(params["id"])
profile = UserProfileComponent.new(user_name: user.name)

# Component:
def render_content : String
  name = @attributes["user_name"]?
  "<div>#{escape_html(name)}</div>"
end
```

### 🚨 Gotcha 5: Forgetting CSS Selector Method

**Problem:** Tests can't easily target component
**Impact:** Brittle tests that break with styling changes
**Solution:** Always implement `css_selector`

```crystal
# ✅ ALWAYS include this
def css_selector : String
  "[data-component='component-name']"
end
```

---

## Quick Reference

### Component Skeleton (Stateless)

```crystal
require "../../stateless_component"

module Components
  module Category
    class NameComponent < StatelessComponent
      def render_content : String
        # Extract attributes
        attr = @attributes["attr"]? || "default"

        # Build HTML
        String.build do |html|
          html << "<div data-component=\"name\">"
          html << "  #{escape_html(attr)}"
          html << "</div>"
        end
      end

      def css_selector : String
        "[data-component='name']"
      end
    end
  end
end
```

### Component Skeleton (Stateful)

```crystal
require "../../stateful_component"

module Components
  module Category
    class NameComponent < StatefulComponent
      protected def initialize_state
        set_state("key", @attributes["key"]? || "default")
      end

      def render_content : String
        value = get_state("key").try(&.as_s?) || ""

        String.build do |html|
          html << "<div data-component=\"name\">"
          html << "  #{escape_html(value)}"
          html << "</div>"
        end
      end

      def css_selector : String
        "[data-component='name']"
      end
    end
  end
end
```

### Common Code Snippets

**Attribute extraction:**
```crystal
value = @attributes["key"]? || "default"
bool_value = @attributes["enabled"]? == "true"
```

**Data attributes:**
```crystal
html << "data-component=\"name\" "
html << "data-variant=\"#{variant}\" "
html << "data-state=\"#{state}\" "
```

**Child rendering:**
```crystal
@children.each do |child|
  case child
  when Component then html << child.render
  when Elements::HTMLElement then html << child.render
  when String then html << escape_html(child)
  end
end
```

**State management:**
```crystal
set_state("key", value)
value = get_state("key").try(&.as_s?)
```

**Composing components:**
```crystal
button = Shared::ButtonComponent.new(label: "Click")
icon = Shared::IconComponent.new(path: svg_path)
html << button.render
html << icon.render
```

---

## Best Practices Checklist

### Before Creating Component

- [ ] Chosen correct base class (Stateless vs Stateful)
- [ ] Determined all required attributes
- [ ] Identified default values for optional attributes
- [ ] Planned component composition strategy

### While Writing Component

- [ ] ✅ Added `data-component` attribute to outermost element
- [ ] ✅ Extracted all attributes at start of `render_content`
- [ ] ✅ Provided sensible defaults for optional attributes
- [ ] ✅ Used `escape_html()` for user content
- [ ] ✅ Implemented `css_selector` method
- [ ] ✅ Added additional data attributes for variants/state
- [ ] ✅ No database/session access in component
- [ ] ✅ Composed from smaller components where possible

### Before Committing

- [ ] Created spec file mirroring source structure
- [ ] Tested rendering with various attribute combinations
- [ ] Tested data attribute presence
- [ ] Tested cache key generation (stateless)
- [ ] Tested state management (stateful)
- [ ] Added documentation comments
- [ ] Verified XSS protection (escaped user content)

---

## Examples from This Codebase

**Simple Component:**
- `src/views/components/shared/icon_component.cr` - SVG icon wrapper
- `src/views/components/shared/button_component.cr` - Configurable button

**Medium Complexity:**
- `src/views/components/shared/card_component.cr` - Content card with header/footer
- `src/views/components/layouts/navigation_component.cr` - Site navigation

**Complex:**
- `src/views/components/forms/login_form_component.cr` - Form with validation
- `src/views/components/pages/dashboard_component.cr` - Full page composition

**Layouts:**
- `src/views/components/layouts/application_layout.cr` - Complete HTML document
- `src/views/components/layouts/mailer_layout.cr` - Email template wrapper

---

## Additional Resources

- **AssetPipeline GitHub**: https://github.com/amberframework/asset_pipeline
- **Component System Overview**: https://github.com/amberframework/asset_pipeline/blob/main/component_system_feature_overview.md
- **Advanced Features**: https://github.com/amberframework/asset_pipeline/blob/main/advanced_component_system_features.md
- **Project Components**: `src/views/components/CLAUDE.md`

---

**Remember:** When in doubt, look at existing components in this codebase as examples. They follow these patterns and conventions consistently.
