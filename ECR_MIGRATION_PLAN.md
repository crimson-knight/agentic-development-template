# ECR to Component Migration Plan

**Date:** 2025-10-10
**Status:** 📋 Ready for Implementation

---

## Overview

This document details the migration of all ECR templates to Asset Pipeline components.

**Total Templates:** 9 files
**Components to Build:** 10 components (1 already complete)
**Estimated Complexity:** High - Full application migration

---

## Template Inventory

### ECR Files Analysis

| File | Type | Dependencies | Complexity |
|------|------|--------------|------------|
| `layouts/application.ecr` | Layout | Navigation, Session, Flash, Content | High |
| `layouts/_nav.ecr` | Partial | Active link detection | Medium |
| `layouts/_session.ecr` | Partial | User auth state | Low |
| `public/home/index.ecr` | Page | Hero, Feature cards, Resource cards | High |
| `public/session/new.ecr` | Page | Login form, CSRF | Medium |
| `authenticated/dashboard/index.ecr` | Page | Stats, Activity, Actions | High |
| `layouts/mailer.ecr` | Email | (Keep as ECR for now) | N/A |
| `public/session/create.ecr` | Empty | (No content) | N/A |
| `users/new.ecr` | Unknown | (Check if used) | TBD |

---

## Component Architecture

### Dependency Graph

```
ApplicationLayout
├── NavigationComponent
│   └── (NavLink logic inline)
├── SessionInfoComponent
│   └── ButtonComponent ✅
├── FlashMessageComponent
│   └── IconComponent
└── [Page Content]
    ├── HomePageComponent
    │   ├── HeroSection
    │   ├── FeatureCard
    │   └── ResourceCard (CardComponent)
    ├── LoginFormComponent (Stateful)
    │   ├── IconComponent
    │   └── ButtonComponent ✅
    └── DashboardComponent
        ├── StatCardComponent
        │   └── IconComponent
        ├── ActivityTimeline
        └── QuickActionButton (ButtonComponent ✅)
```

---

## Components to Build

### Phase 1: Foundation Components (Shared)

#### 1. IconComponent ✨ NEW
**Type:** Stateless
**Purpose:** Render SVG icons consistently
**File:** `src/components/shared/icon_component.cr`

**Attributes:**
- `path` - SVG path data
- `size` - Icon size class (default: "h-6 w-6")
- `color` - Icon color class (default: "currentColor")
- `viewBox` - SVG viewBox (default: "0 0 24 24")

**Usage:**
```crystal
IconComponent.new(
  path: "M13 10V3L4 14h7v7l9-11h-7z",
  size: "h-5 w-5",
  color: "text-green-400"
)
```

---

#### 2. CardComponent ✨ NEW
**Type:** Stateless
**Purpose:** Reusable content card with icon/title/description
**File:** `src/components/shared/card_component.cr`

**Attributes:**
- `title` - Card title
- `description` - Card description
- `icon_path` - SVG icon path
- `link_href` - Optional link URL
- `link_text` - Link text
- `link_target` - Link target (_blank, etc.)

**Usage:**
```crystal
CardComponent.new(
  title: "Amber Documentation",
  description: "Complete guide...",
  icon_path: "M12 6.253v13...",
  link_href: "https://docs.amberframework.org",
  link_target: "_blank"
)
```

---

#### 3. StatCardComponent ✨ NEW
**Type:** Stateless
**Purpose:** Dashboard statistics card with icon, value, trend
**File:** `src/components/shared/stat_card_component.cr`

**Attributes:**
- `title` - Stat label (e.g., "Total Users")
- `value` - Main value (e.g., "1,247")
- `icon_path` - SVG icon path
- `trend_direction` - "up", "down", or nil
- `trend_value` - Trend percentage (e.g., "12%")
- `bg_color` - Icon background color (default: "indigo")

**Usage:**
```crystal
StatCardComponent.new(
  title: "Total Users",
  value: "1,247",
  icon_path: "M12 4.354a4 4 0 110 5.292...",
  trend_direction: "up",
  trend_value: "12%"
)
```

---

#### 4. FlashMessageComponent ✨ NEW
**Type:** Stateless
**Purpose:** Alert/notification messages with auto-styling
**File:** `src/components/shared/flash_message_component.cr`

**Attributes:**
- `type` - "success", "error", "info", "warning"
- `message` - Flash message text

**Auto-styling:**
- Success: green background, green icon (checkmark)
- Error: red background, red icon (X)
- Info: blue background, blue icon (i)
- Warning: yellow background, yellow icon (!)

**Usage:**
```crystal
FlashMessageComponent.new(
  type: "success",
  message: "Login successful!"
)
```

---

### Phase 2: Layout Components

#### 5. NavigationComponent ✨ NEW
**Type:** Stateless
**Purpose:** Top navigation bar with logo, links, session info
**File:** `src/components/layouts/navigation_component.cr`

**Attributes:**
- `current_path` - Current request path for active styling
- `logged_in` - Whether user is authenticated (Bool as String)
- `current_user` - User object (optional)

**Features:**
- Logo and branding
- Home link (active state detection)
- Sign In link (when not logged in)
- Session info component (when logged in)
- Mobile menu button (responsive)

**Usage:**
```crystal
NavigationComponent.new(
  current_path: "/dashboard",
  logged_in: "true",
  current_user: current_user.to_json
)
```

---

#### 6. SessionInfoComponent ✨ NEW
**Type:** Stateless
**Purpose:** Display logged-in user info and logout button
**File:** `src/components/layouts/session_info_component.cr`

**Attributes:**
- `user_email` - User's email address
- `profile_href` - Profile link URL (default: "/profile")
- `logout_href` - Logout link URL (default: "/logout")

**Usage:**
```crystal
SessionInfoComponent.new(
  user_email: "user@example.com",
  profile_href: "/profile",
  logout_href: "/logout"
)
```

---

#### 7. ApplicationLayout ✨ NEW
**Type:** Stateless
**Purpose:** Complete HTML document structure
**File:** `src/components/layouts/application_layout.cr`

**Attributes:**
- `title` - Page title (default: "AgentC App Template")
- `content` - Main page content HTML
- `current_path` - Current path (for navigation)
- `logged_in` - Authentication state
- `current_user` - User data (JSON or object)
- `flash_messages` - Hash of flash messages

**Features:**
- Complete HTML structure (doctype, head, body)
- Meta tags and viewport
- Tailwind CSS CDN
- Favicon links
- Asset Pipeline import map
- Stimulus controller initialization
- Navigation component
- Flash messages
- Main content area
- Auto-reload script (development)

**Usage:**
```crystal
ApplicationLayout.new(
  title: "Dashboard",
  content: page_component.render,
  current_path: request.path,
  logged_in: logged_in?.to_s,
  current_user: current_user.try(&.email),
  flash_messages: flash.to_h
)
```

---

### Phase 3: Page Components

#### 8. HomePageComponent ✨ NEW
**Type:** Stateless
**Purpose:** Landing page with hero, features, resources
**File:** `src/components/pages/home_page_component.cr`

**Attributes:**
- `logged_in` - Authentication state (Bool as String)

**Sections:**
1. **Hero Section**
   - Title with gradient text
   - Description
   - CTA button (changes based on auth state)
   - Documentation link
   - Decorative SVG background
   - Gradient image placeholder

2. **Features Section** (4 cards)
   - Lightning Fast
   - Type Safe
   - Developer Friendly
   - Production Ready

3. **Resources Section** (3 cards)
   - Amber Documentation
   - Awesome Crystal
   - Join Discord

**Usage:**
```crystal
HomePageComponent.new(logged_in: "false")
```

---

#### 9. LoginFormComponent ✨ NEW
**Type:** Stateful (manages form state)
**Purpose:** Login form with validation
**File:** `src/components/forms/login_form_component.cr`

**Attributes:**
- `csrf_token` - CSRF token from controller
- `email_value` - Pre-filled email (optional)
- `action` - Form action URL (default: "/login")

**State:**
- `email` - Current email input
- `password` - Current password input
- `errors` - Validation errors hash
- `submitting` - Form submission state

**Features:**
- User icon header
- Email/password fields
- Remember me checkbox
- Forgot password link
- Sign up link
- Stimulus controller integration
- Accessibility (sr-only labels)
- Responsive design

**Usage:**
```crystal
LoginFormComponent.new(
  csrf_token: csrf_token,
  email_value: params["email"]?
)
```

---

#### 10. DashboardComponent ✨ NEW
**Type:** Stateless
**Purpose:** User dashboard with stats, activity, actions
**File:** `src/components/pages/dashboard_component.cr`

**Attributes:**
- `user_email` - Current user email (optional, for personalization)

**Sections:**
1. **Header**
   - Title and welcome message
   - "New Project" button

2. **Stats Grid** (4 stat cards)
   - Total Users (1,247, +12%)
   - Revenue ($24,780, +8%)
   - Growth Rate (24.7%, +3.2%)
   - Conversion (3.24%, -1.2%)

3. **Content Grid** (2 columns)
   - Recent Activity (timeline with 3 items)
   - Quick Actions (3 action buttons)

**Usage:**
```crystal
DashboardComponent.new(user_email: current_user.try(&.email))
```

---

## Implementation Order

### Step 1: Shared Components (Foundation)
Build in this order (dependencies first):

1. ✅ **ButtonComponent** - Already implemented!
2. **IconComponent** - No dependencies
3. **CardComponent** - Uses IconComponent
4. **StatCardComponent** - Uses IconComponent
5. **FlashMessageComponent** - Uses IconComponent

**Deliverable:** All shared components working with tests

---

### Step 2: Layout Components
Build in this order:

6. **SessionInfoComponent** - Uses ButtonComponent
7. **NavigationComponent** - Uses SessionInfoComponent
8. **ApplicationLayout** - Uses Navigation + FlashMessage

**Deliverable:** Complete layout system

---

### Step 3: Page Components
Build in this order:

9. **HomePageComponent** - Uses CardComponent, ButtonComponent
10. **LoginFormComponent** - Uses ButtonComponent, IconComponent (Stateful!)
11. **DashboardComponent** - Uses StatCardComponent, ButtonComponent

**Deliverable:** All pages rendering via components

---

### Step 4: Controller Updates
Update controllers in this order:

1. **HomeController** - Simplest (just pass logged_in state)
2. **SessionController#new** - Login page (pass CSRF token)
3. **DashboardController** - Authenticated page

**Deliverable:** All controllers using components

---

### Step 5: Testing & Validation
1. Component unit tests (14+ tests per component)
2. Controller integration tests
3. Manual browser testing
4. Responsive design verification

**Deliverable:** Fully tested component system

---

### Step 6: Cleanup
1. Archive old ECR templates to `src/views/legacy/`
2. Update documentation
3. Create migration summary

**Deliverable:** Clean codebase with components only

---

## Data Flow Patterns

### From Controller to Component

```crystal
# In controller
def index
  page = Components::Pages::HomePageComponent.new(
    logged_in: logged_in?.to_s  # Bool to String
  )

  layout = Components::Layouts::ApplicationLayout.new(
    title: "Home",
    content: page.render,
    current_path: request.path,
    logged_in: logged_in?.to_s,
    current_user: current_user.try(&.email),
    flash_messages: {"success" => "Welcome!"} # Hash
  )

  render html: layout.render
end
```

### Accessing Context in Components

Components receive ALL data via attributes:
- No `context` access
- No `flash` access
- No `current_user` access
- Everything passed explicitly

### Handling Optional Data

```crystal
# In component
user_email = @attributes["user_email"]? || "Guest"
logged_in = @attributes["logged_in"]? == "true"
```

---

## Testing Strategy

### Component Tests

Each component needs:

```crystal
describe Components::Shared::MyComponent do
  describe "rendering" do
    it "renders with default attributes" do
      component = Components::Shared::MyComponent.new
      component.render.should contain("expected")
    end

    it "accepts custom attributes" do
      component = Components::Shared::MyComponent.new(prop: "value")
      component.render.should contain("value")
    end
  end

  describe "css_selector" do
    it "returns correct selector" do
      component = Components::Shared::MyComponent.new
      component.css_selector.should eq(".my-component")
    end
  end

  describe "caching" (if stateless) do
    it "generates cache keys" do
      comp1 = Components::Shared::MyComponent.new(prop: "value")
      comp2 = Components::Shared::MyComponent.new(prop: "value")
      comp1.cache_key.should eq(comp2.cache_key)
    end
  end
end
```

### Integration Tests

Update existing controller specs:

```crystal
describe "GET /" do
  it "renders homepage component" do
    response = get("/")

    response.status_code.should eq(200)
    response.body.should contain("Build amazing")  # Hero title
    response.body.should contain("Features")  # Features section
  end
end
```

---

## Migration Checklist

### Shared Components
- [x] ButtonComponent (already complete!)
- [ ] IconComponent
- [ ] CardComponent
- [ ] StatCardComponent
- [ ] FlashMessageComponent

### Shared Component Tests
- [x] ButtonComponent tests (14 passing)
- [ ] IconComponent tests
- [ ] CardComponent tests
- [ ] StatCardComponent tests
- [ ] FlashMessageComponent tests

### Layout Components
- [ ] SessionInfoComponent
- [ ] NavigationComponent
- [ ] ApplicationLayout

### Layout Component Tests
- [ ] SessionInfoComponent tests
- [ ] NavigationComponent tests
- [ ] ApplicationLayout tests

### Page Components
- [ ] HomePageComponent
- [ ] LoginFormComponent
- [ ] DashboardComponent

### Page Component Tests
- [ ] HomePageComponent tests
- [ ] LoginFormComponent tests
- [ ] DashboardComponent tests

### Controller Updates
- [ ] HomeController → use HomePageComponent
- [ ] SessionController#new → use LoginFormComponent
- [ ] DashboardController → use DashboardComponent
- [ ] All controllers use ApplicationLayout

### Integration & Testing
- [ ] All controller specs updated
- [ ] Manual browser testing
- [ ] Mobile responsiveness verified
- [ ] Flash messages work correctly

### Cleanup
- [ ] Archive ECR templates to `src/views/legacy/`
- [ ] Remove ECR references from controllers
- [ ] Update CLAUDE.md documentation
- [ ] Create migration summary document

---

## Estimated Complexity

**Components:** 10 total (1 complete)
**Lines of Code:** ~2,500-3,000 (components + tests)
**Tests:** ~140-160 tests (14+ per component)

**Time Breakdown:**
- Shared components: 35% of work
- Layout components: 30% of work
- Page components: 25% of work
- Testing & integration: 10% of work

---

## Success Criteria

✅ All ECR templates converted to components
✅ All components have comprehensive tests
✅ All controllers use components
✅ 100% test coverage for new components
✅ No ECR templates in active use
✅ Documentation updated

---

**Last Updated:** 2025-10-10
**Ready for Implementation:** YES
**Next Step:** Build IconComponent

