---
name: asset-pipeline-element-reference
description: Complete API reference for all AssetPipeline HTML elements, attributes, and constructors
tags: [asset-pipeline, elements, html, attributes, api-reference, lookup]
applies_to: ["src/views/components/**/*.cr", "lib/asset_pipeline/**/*.cr"]
---

# AssetPipeline Element & Attribute Reference

Complete API reference for all 87 HTML5 elements available in the AssetPipeline component system. Use this as your comprehensive lookup guide when building components.

## 🎯 Quick Lookup

**Need to find an element quickly?**
- **Forms** → See [Form Elements](#form-elements) (Form, Input, Button, Select, Textarea, Label)
- **Layout** → See [Sectioning Elements](#sectioning-elements) (Header, Footer, Main, Nav, Section, Article)
- **Text** → See [Text Elements](#text-semantics-elements) (P, Span, A, Strong, Em, Code)
- **Containers** → See [Grouping Elements](#grouping-elements) (Div, Section, Article, Aside)
- **Tables** → See [Table Elements](#table-elements) (Table, Tr, Td, Th, Thead, Tbody)
- **Media** → See [Embedded Content](#embedded-content) (Img, Video, Audio, Svg, Canvas)

**Need attribute information?**
- **Global attributes** (work on all elements) → See [Global Attributes](#global-attributes)
- **Element-specific** → Check the element's entry below
- **Form attributes** → See [Form-Specific Attributes](#form-specific-attributes)
- **Event handlers** → See [Event Handler Attributes](#event-handler-attributes)

---

## 📖 Table of Contents

1. [Constructor Patterns](#constructor-patterns)
2. [Global Attributes](#global-attributes)
3. [Element Catalog by Category](#element-catalog)
   - [Document Elements](#document-elements)
   - [Sectioning Elements](#sectioning-elements)
   - [Grouping Elements](#grouping-elements)
   - [Text Semantics Elements](#text-semantics-elements)
   - [Form Elements](#form-elements)
   - [Table Elements](#table-elements)
   - [Embedded Content](#embedded-content)
   - [Interactive Elements](#interactive-elements)
   - [Void Elements](#void-elements)
4. [Form-Specific Attributes](#form-specific-attributes)
5. [Event Handler Attributes](#event-handler-attributes)
6. [Common Patterns](#common-patterns)

---

## Constructor Patterns

### Pattern 1: Standard Constructor (Attributes Only)

```crystal
# Create element with attributes
div = Elements::Div.new(
  class: "container",
  id: "main-content",
  data_component: "wrapper"
)

# Add content later
div << "Hello World"
div << Elements::Span.new(class: "highlight") { "Important" }

# Render to HTML
html = div.render
```

### Pattern 2: Constructor with Block (Attributes + Content)

```crystal
# Create element with attributes AND content in one call
div = Elements::Div.new(class: "card") do
  "Card content goes here"
end

# Or with multiple content items
div = Elements::Div.new(class: "card") do |container|
  container << Elements::H2.new { "Title" }
  container << Elements::P.new { "Description" }
end
```

### Pattern 3: Void Elements (Self-Closing)

```crystal
# Void elements don't have content or closing tags
br = Elements::Br.new
hr = Elements::Hr.new(class: "divider")
img = Elements::Img.new(
  src: "/images/logo.png",
  alt: "Company Logo",
  width: "200",
  height: "100"
)

# Render directly
html = img.render  # => <img src="/images/logo.png" alt="Company Logo" width="200" height="100">
```

### Pattern 4: Input Types (Specialized Constructors)

```crystal
# Input elements have type-specific factory methods
email_input = Elements::Input.email(
  name: "user_email",
  required: true,
  placeholder: "Enter your email"
)

password_input = Elements::Input.password(
  name: "user_password",
  minlength: "8",
  required: true
)

checkbox = Elements::Input.checkbox(
  name: "agree_terms",
  value: "yes",
  checked: true
)

# Available input types:
# .text, .email, .password, .number, .tel, .url, .search,
# .checkbox, .radio, .submit, .button, .reset, .hidden,
# .date, .time, .datetime_local, .file, .color
```

### Pattern 5: Content-Focused Elements

```crystal
# Elements that are primarily about content
p = Elements::P.new { "This is a paragraph of text." }
h1 = Elements::H1.new { "Main Heading" }
span = Elements::Span.new(class: "label") { "Status: Active" }

# With interpolation
username = "Alice"
p = Elements::P.new { "Welcome, #{username}!" }
```

### Pattern 6: Building Complex Structures

```crystal
# Build nested structures programmatically
form = Elements::Form.new(action: "/login", method: "post") do |f|
  f << Elements::Div.new(class: "form-group") do |group|
    group << Elements::Label.new(for: "email") { "Email:" }
    group << Elements::Input.email(
      id: "email",
      name: "email",
      required: true
    )
  end

  f << Elements::Div.new(class: "form-group") do |group|
    group << Elements::Label.new(for: "password") { "Password:" }
    group << Elements::Input.password(
      id: "password",
      name: "password",
      required: true
    )
  end

  f << Elements::Button.new(type: "submit") { "Login" }
end
```

---

## Global Attributes

These attributes work on **ALL HTML elements**:

### Core Global Attributes

| Attribute | Type | Description | Example |
|-----------|------|-------------|---------|
| `class` | String | CSS class names (space-separated) | `class: "btn btn-primary"` |
| `id` | String | Unique identifier | `id: "main-header"` |
| `style` | String | Inline CSS styles | `style: "color: red; font-size: 16px"` |
| `title` | String | Advisory information (tooltip) | `title: "Click to expand"` |
| `lang` | String | Language of element content | `lang: "en"` |
| `dir` | String | Text direction (`ltr`, `rtl`, `auto`) | `dir: "ltr"` |
| `hidden` | Boolean | Hide element | `hidden: true` |
| `tabindex` | String/Int | Tab order for keyboard navigation | `tabindex: "0"` |
| `accesskey` | String | Keyboard shortcut | `accesskey: "s"` |
| `contenteditable` | String | Allow editing (`true`, `false`) | `contenteditable: "true"` |
| `draggable` | String | Enable drag-and-drop (`true`, `false`) | `draggable: "true"` |
| `spellcheck` | String | Enable spell checking (`true`, `false`) | `spellcheck: "true"` |
| `translate` | String | Allow translation (`yes`, `no`) | `translate: "no"` |

### Data Attributes

```crystal
# Custom data attributes (automatically prefixed with data-)
div = Elements::Div.new(
  data_component: "card",           # => data-component="card"
  data_variant: "primary",          # => data-variant="primary"
  data_user_id: "123",              # => data-user-id="123"
  data_config: '{"key": "value"}'   # => data-config='{"key": "value"}'
)
```

**Naming Convention**: Use underscores in Crystal, they become hyphens in HTML
- `data_user_id` → `data-user-id`
- `data_component_name` → `data-component-name`

### ARIA Attributes

Accessibility attributes for screen readers:

```crystal
button = Elements::Button.new(
  aria_label: "Close dialog",
  aria_expanded: "false",
  aria_controls: "menu",
  role: "button"
)
```

**Common ARIA attributes:**
- `aria_label` - Accessibility label
- `aria_labelledby` - ID of labeling element
- `aria_describedby` - ID of description element
- `aria_expanded` - Expanded state (`true`, `false`)
- `aria_hidden` - Hide from screen readers (`true`, `false`)
- `aria_live` - Live region update (`polite`, `assertive`, `off`)
- `aria_controls` - ID of controlled element
- `role` - ARIA role (`button`, `navigation`, `main`, etc.)

---

## Element Catalog

### Document Elements

Elements that structure the HTML document.

#### `Html` - Document Root
```crystal
html = Elements::Html.new(lang: "en") do |doc|
  doc << Elements::Head.new { /* head content */ }
  doc << Elements::Body.new { /* body content */ }
end
```
**Attributes**: `lang`, `dir`, global attributes

#### `Head` - Document Metadata Container
```crystal
head = Elements::Head.new do |h|
  h << Elements::Title.new { "Page Title" }
  h << Elements::Meta.new(charset: "UTF-8")
  h << Elements::Link.new(rel: "stylesheet", href: "/css/app.css")
end
```

#### `Body` - Document Body
```crystal
body = Elements::Body.new(class: "dark-theme") do
  # Page content
end
```
**Attributes**: All global attributes, event handlers

#### `Title` - Document Title
```crystal
title = Elements::Title.new { "My Application - Dashboard" }
```

#### `Meta` - Metadata
```crystal
# Character set
meta = Elements::Meta.new(charset: "UTF-8")

# Viewport
meta = Elements::Meta.new(
  name: "viewport",
  content: "width=device-width, initial-scale=1"
)

# Description
meta = Elements::Meta.new(
  name: "description",
  content: "App description for SEO"
)
```
**Attributes**: `charset`, `name`, `content`, `http_equiv`

#### `Link` - External Resource Link
```crystal
# Stylesheet
link = Elements::Link.new(
  rel: "stylesheet",
  href: "/css/app.css"
)

# Icon
link = Elements::Link.new(
  rel: "icon",
  type: "image/x-icon",
  href: "/favicon.ico"
)

# Preload
link = Elements::Link.new(
  rel: "preload",
  href: "/fonts/custom.woff2",
  as: "font",
  type: "font/woff2",
  crossorigin: "anonymous"
)
```
**Attributes**: `href`, `rel`, `type`, `media`, `sizes`, `crossorigin`, `as`

#### `Style` - Inline Stylesheet
```crystal
style = Elements::Style.new do
  <<-CSS
  .custom-class {
    color: red;
    font-size: 16px;
  }
  CSS
end
```

#### `Script` - JavaScript
```crystal
# External script
script = Elements::Script.new(
  src: "/js/app.js",
  defer: true
)

# Inline script
script = Elements::Script.new do
  "console.log('Hello from inline script');"
end

# Module script
script = Elements::Script.new(
  src: "/js/module.js",
  type: "module"
)
```
**Attributes**: `src`, `type`, `async`, `defer`, `crossorigin`, `integrity`, `nomodule`

---

### Sectioning Elements

Elements that define document structure and sections.

#### `Header` - Section or Page Header
```crystal
header = Elements::Header.new(class: "site-header") do |h|
  h << Elements::Nav.new { /* navigation */ }
  h << Elements::H1.new { "Site Title" }
end
```

#### `Footer` - Section or Page Footer
```crystal
footer = Elements::Footer.new(class: "site-footer") do
  "© 2025 Company Name. All rights reserved."
end
```

#### `Main` - Main Content
```crystal
# Only ONE main element per document
main = Elements::Main.new(class: "main-content") do
  # Primary content goes here
end
```

#### `Nav` - Navigation Section
```crystal
nav = Elements::Nav.new(class: "primary-nav") do |n|
  n << Elements::Ul.new do |ul|
    ul << Elements::Li.new { Elements::A.new(href: "/") { "Home" } }
    ul << Elements::Li.new { Elements::A.new(href: "/about") { "About" } }
    ul << Elements::Li.new { Elements::A.new(href: "/contact") { "Contact" } }
  end
end
```

#### `Section` - Generic Section
```crystal
section = Elements::Section.new(class: "features") do |s|
  s << Elements::H2.new { "Features" }
  s << Elements::P.new { "Description..." }
end
```

#### `Article` - Self-Contained Content
```crystal
article = Elements::Article.new(class: "blog-post") do |a|
  a << Elements::H2.new { "Post Title" }
  a << Elements::P.new { "Post content..." }
  a << Elements::Footer.new { "Published: 2025-01-01" }
end
```

#### `Aside` - Sidebar Content
```crystal
aside = Elements::Aside.new(class: "sidebar") do
  # Related content, ads, navigation
end
```

#### Headings (`H1` through `H6`)
```crystal
h1 = Elements::H1.new { "Main Page Title" }
h2 = Elements::H2.new(class: "section-title") { "Section Title" }
h3 = Elements::H3.new { "Subsection Title" }
# ... through H6
```

---

### Grouping Elements

Elements for grouping content.

#### `Div` - Generic Container
```crystal
div = Elements::Div.new(
  class: "container",
  id: "main",
  data_component: "wrapper"
) do
  "Content goes here"
end
```
**Most common container element. Use for layout and grouping.**

#### `P` - Paragraph
```crystal
p = Elements::P.new(class: "intro") do
  "This is a paragraph of text content."
end
```

#### `Span` - Inline Container
```crystal
span = Elements::Span.new(class: "highlight") do
  "Important text"
end
```

#### `Pre` - Preformatted Text
```crystal
pre = Elements::Pre.new do
  <<-CODE
  function example() {
    return true;
  }
  CODE
end
```

#### `Blockquote` - Block Quotation
```crystal
blockquote = Elements::Blockquote.new(cite: "https://source.com") do |bq|
  bq << Elements::P.new { "Quote text here..." }
  bq << Elements::Footer.new { "— Author Name" }
end
```
**Attributes**: `cite`

#### `Figure` - Self-Contained Content
```crystal
figure = Elements::Figure.new do |f|
  f << Elements::Img.new(src: "/chart.png", alt: "Sales Chart")
  f << Elements::Figcaption.new { "Figure 1: Q4 Sales Performance" }
end
```

#### `Figcaption` - Figure Caption
```crystal
figcaption = Elements::Figcaption.new { "Caption text" }
```

#### Lists

**Unordered List (`Ul`):**
```crystal
ul = Elements::Ul.new(class: "feature-list") do |list|
  list << Elements::Li.new { "First item" }
  list << Elements::Li.new { "Second item" }
  list << Elements::Li.new { "Third item" }
end
```

**Ordered List (`Ol`):**
```crystal
ol = Elements::Ol.new(start: "5", type: "1") do |list|
  list << Elements::Li.new { "Step five" }
  list << Elements::Li.new { "Step six" }
end
```
**Attributes**: `start`, `type` (`1`, `A`, `a`, `I`, `i`), `reversed`

**Description List (`Dl`, `Dt`, `Dd`):**
```crystal
dl = Elements::Dl.new do |list|
  list << Elements::Dt.new { "Name" }
  list << Elements::Dd.new { "Value" }
  list << Elements::Dt.new { "Email" }
  list << Elements::Dd.new { "user@example.com" }
end
```

#### `Hr` - Thematic Break (Void)
```crystal
hr = Elements::Hr.new(class: "section-divider")
```

---

### Text Semantics Elements

Elements for inline text formatting and semantics.

#### `A` - Hyperlink
```crystal
# External link
a = Elements::A.new(
  href: "https://example.com",
  target: "_blank",
  rel: "noopener noreferrer"
) { "Visit Example" }

# Internal link
a = Elements::A.new(href: "/about") { "About Us" }

# Email link
a = Elements::A.new(href: "mailto:info@example.com") { "Email Us" }

# Phone link
a = Elements::A.new(href: "tel:+1234567890") { "Call Us" }
```
**Attributes**: `href`, `target`, `rel`, `download`, `hreflang`, `type`

#### `Strong` - Strong Importance
```crystal
strong = Elements::Strong.new { "Very important text" }
```

#### `Em` - Emphasis
```crystal
em = Elements::Em.new { "Emphasized text" }
```

#### `Small` - Fine Print
```crystal
small = Elements::Small.new { "Terms and conditions apply" }
```

#### `Code` - Inline Code
```crystal
code = Elements::Code.new { "const x = 42;" }

# Combined with pre for code blocks
pre = Elements::Pre.new do
  Elements::Code.new do
    <<-CODE
    function hello() {
      return "world";
    }
    CODE
  end.render
end
```

#### `Kbd` - Keyboard Input
```crystal
kbd = Elements::Kbd.new { "Ctrl+C" }
```

#### `Var` - Variable
```crystal
var = Elements::Var.new { "x" }
# Usage: The formula is <var>x</var> + <var>y</var> = <var>z</var>
```

#### `Samp` - Sample Output
```crystal
samp = Elements::Samp.new { "Error: File not found" }
```

#### `Sub` - Subscript
```crystal
sub = Elements::Sub.new { "2" }
# Usage: H<sub>2</sub>O
```

#### `Sup` - Superscript
```crystal
sup = Elements::Sup.new { "2" }
# Usage: E = mc<sup>2</sup>
```

#### `Mark` - Highlighted Text
```crystal
mark = Elements::Mark.new { "search term" }
```

#### `Cite` - Citation
```crystal
cite = Elements::Cite.new { "Book Title" }
```

#### `Ins` - Inserted Text
```crystal
ins = Elements::Ins.new(
  cite: "/changes",
  datetime: "2025-01-15"
) { "New content" }
```
**Attributes**: `cite`, `datetime`

#### `Del` - Deleted Text
```crystal
del = Elements::Del.new(
  cite: "/changes",
  datetime: "2025-01-15"
) { "Old content" }
```
**Attributes**: `cite`, `datetime`

#### `Br` - Line Break (Void)
```crystal
br = Elements::Br.new
# Usage: line1.render + br.render + line2.render
```

---

### Form Elements

Elements for creating interactive forms.

#### `Form` - Form Container
```crystal
form = Elements::Form.new(
  action: "/submit",
  method: "post",
  enctype: "multipart/form-data"
) do |f|
  f << Elements::Input.text(name: "username")
  f << Elements::Button.new(type: "submit") { "Submit" }
end
```
**Attributes**: `action`, `method` (`get`, `post`), `enctype`, `target`, `autocomplete`, `novalidate`, `name`

#### `Input` - Input Field (Void)

**Text Input:**
```crystal
input = Elements::Input.text(
  name: "username",
  id: "username",
  placeholder: "Enter username",
  required: true,
  minlength: "3",
  maxlength: "20",
  autocomplete: "username"
)
```

**Email Input:**
```crystal
input = Elements::Input.email(
  name: "email",
  required: true,
  placeholder: "user@example.com"
)
```

**Password Input:**
```crystal
input = Elements::Input.password(
  name: "password",
  required: true,
  minlength: "8",
  autocomplete: "current-password"
)
```

**Number Input:**
```crystal
input = Elements::Input.number(
  name: "quantity",
  min: "1",
  max: "100",
  step: "1",
  value: "1"
)
```

**Checkbox:**
```crystal
checkbox = Elements::Input.checkbox(
  name: "agree",
  value: "yes",
  checked: true,
  required: true
)
```

**Radio Button:**
```crystal
radio1 = Elements::Input.radio(
  name: "plan",
  value: "basic",
  checked: true
)
radio2 = Elements::Input.radio(
  name: "plan",
  value: "premium"
)
```

**File Upload:**
```crystal
input = Elements::Input.file(
  name: "avatar",
  accept: "image/png,image/jpeg",
  multiple: true
)
```

**Date/Time Inputs:**
```crystal
date = Elements::Input.date(name: "birthday")
time = Elements::Input.time(name: "appointment")
datetime = Elements::Input.datetime_local(name: "event_start")
```

**Other Input Types:**
```crystal
search = Elements::Input.search(name: "q", placeholder: "Search...")
tel = Elements::Input.tel(name: "phone", pattern: "[0-9]{3}-[0-9]{3}-[0-9]{4}")
url = Elements::Input.url(name: "website", placeholder: "https://")
color = Elements::Input.color(name: "theme_color", value: "#ff0000")
hidden = Elements::Input.hidden(name: "csrf_token", value: token)
range = Elements::Input.range(name: "volume", min: "0", max: "100", value: "50")
```

**Common Input Attributes:**
- `name` - Form field name
- `value` - Initial value
- `placeholder` - Placeholder text
- `required` - Required field
- `readonly` - Read-only field
- `disabled` - Disabled field
- `autocomplete` - Autocomplete hint
- `pattern` - Validation regex
- `minlength`, `maxlength` - Text length constraints
- `min`, `max`, `step` - Number constraints
- `multiple` - Allow multiple values (file, email, select)
- `accept` - File type filter

#### `Textarea` - Multi-line Text Input
```crystal
textarea = Elements::Textarea.new(
  name: "message",
  rows: "5",
  cols: "40",
  placeholder: "Enter your message...",
  required: true,
  maxlength: "500"
) { "Default content" }
```
**Attributes**: `name`, `rows`, `cols`, `placeholder`, `required`, `readonly`, `disabled`, `maxlength`, `minlength`, `wrap`

#### `Select` - Dropdown Selection
```crystal
select = Elements::Select.new(
  name: "country",
  required: true,
  multiple: false
) do |s|
  s << Elements::Option.new(value: "", selected: true) { "Choose a country" }
  s << Elements::Option.new(value: "us") { "United States" }
  s << Elements::Option.new(value: "ca") { "Canada" }
  s << Elements::Option.new(value: "uk") { "United Kingdom" }
end

# With optgroups
select = Elements::Select.new(name: "location") do |s|
  s << Elements::Optgroup.new(label: "North America") do |group|
    group << Elements::Option.new(value: "us") { "United States" }
    group << Elements::Option.new(value: "ca") { "Canada" }
  end
  s << Elements::Optgroup.new(label: "Europe") do |group|
    group << Elements::Option.new(value: "uk") { "United Kingdom" }
    group << Elements::Option.new(value: "de") { "Germany" }
  end
end
```
**Attributes**: `name`, `multiple`, `size`, `required`, `disabled`

#### `Option` - Select Option
```crystal
option = Elements::Option.new(
  value: "value",
  selected: true,
  disabled: false
) { "Display Text" }
```
**Attributes**: `value`, `selected`, `disabled`, `label`

#### `Optgroup` - Option Group
```crystal
optgroup = Elements::Optgroup.new(label: "Group Name") do
  # Options here
end
```
**Attributes**: `label`, `disabled`

#### `Button` - Button Element
```crystal
# Submit button
submit = Elements::Button.new(type: "submit") { "Submit Form" }

# Regular button
button = Elements::Button.new(
  type: "button",
  class: "btn btn-primary",
  onclick: "handleClick()"
) { "Click Me" }

# Reset button
reset = Elements::Button.new(type: "reset") { "Reset Form" }
```
**Attributes**: `type` (`submit`, `button`, `reset`), `name`, `value`, `disabled`, `form`

#### `Label` - Form Label
```crystal
# Associated with input via 'for' attribute
label = Elements::Label.new(for: "email-input") { "Email Address:" }
email = Elements::Input.email(id: "email-input", name: "email")

# Wrapping input (implicit association)
label = Elements::Label.new do |l|
  l << "Email Address: "
  l << Elements::Input.email(name: "email").render
end
```
**Attributes**: `for` (ID of associated input)

#### `Fieldset` - Field Grouping
```crystal
fieldset = Elements::Fieldset.new(disabled: false) do |fs|
  fs << Elements::Legend.new { "Personal Information" }
  fs << Elements::Label.new(for: "name") { "Name:" }
  fs << Elements::Input.text(id: "name", name: "name")
  fs << Elements::Br.new.render
  fs << Elements::Label.new(for: "email") { "Email:" }
  fs << Elements::Input.email(id: "email", name: "email")
end
```
**Attributes**: `disabled`, `form`, `name`

#### `Legend` - Fieldset Caption
```crystal
legend = Elements::Legend.new { "Shipping Address" }
```

---

### Table Elements

Elements for creating data tables.

#### Complete Table Example
```crystal
table = Elements::Table.new(class: "data-table") do |t|
  # Table header
  t << Elements::Thead.new do |thead|
    thead << Elements::Tr.new do |tr|
      tr << Elements::Th.new { "ID" }
      tr << Elements::Th.new { "Name" }
      tr << Elements::Th.new { "Email" }
      tr << Elements::Th.new { "Actions" }
    end
  end

  # Table body
  t << Elements::Tbody.new do |tbody|
    tbody << Elements::Tr.new do |tr|
      tr << Elements::Td.new { "1" }
      tr << Elements::Td.new { "Alice" }
      tr << Elements::Td.new { "alice@example.com" }
      tr << Elements::Td.new { "Edit | Delete" }
    end
    tbody << Elements::Tr.new do |tr|
      tr << Elements::Td.new { "2" }
      tr << Elements::Td.new { "Bob" }
      tr << Elements::Td.new { "bob@example.com" }
      tr << Elements::Td.new { "Edit | Delete" }
    end
  end

  # Optional: Table footer
  t << Elements::Tfoot.new do |tfoot|
    tfoot << Elements::Tr.new do |tr|
      tr << Elements::Td.new(colspan: "4") { "2 total users" }
    end
  end
end
```

#### `Table` - Table Container
**Attributes**: global attributes, `border` (deprecated, use CSS)

#### `Thead` - Table Header Group
Wraps header rows.

#### `Tbody` - Table Body Group
Wraps body rows.

#### `Tfoot` - Table Footer Group
Wraps footer rows.

#### `Tr` - Table Row
```crystal
tr = Elements::Tr.new(class: "highlight") do |row|
  row << Elements::Td.new { "Cell 1" }
  row << Elements::Td.new { "Cell 2" }
end
```

#### `Th` - Table Header Cell
```crystal
th = Elements::Th.new(
  scope: "col",
  colspan: "2",
  rowspan: "1"
) { "Column Header" }
```
**Attributes**: `scope` (`row`, `col`, `rowgroup`, `colgroup`), `colspan`, `rowspan`, `headers`

#### `Td` - Table Data Cell
```crystal
td = Elements::Td.new(
  colspan: "2",
  rowspan: "1",
  headers: "header-id"
) { "Cell content" }
```
**Attributes**: `colspan`, `rowspan`, `headers`

#### `Caption` - Table Caption
```crystal
caption = Elements::Caption.new { "User Directory" }
# Place as first child of table
```

---

### Embedded Content

Elements for embedding media and external content.

#### `Img` - Image (Void)
```crystal
img = Elements::Img.new(
  src: "/images/photo.jpg",
  alt: "Description of image",
  width: "800",
  height: "600",
  loading: "lazy",
  decoding: "async"
)
```
**Attributes**:
- `src` (required) - Image URL
- `alt` (required for accessibility) - Alternative text
- `width`, `height` - Dimensions in pixels
- `loading` (`lazy`, `eager`) - Loading strategy
- `decoding` (`async`, `sync`, `auto`) - Decoding hint
- `srcset` - Responsive image sources
- `sizes` - Image size hints
- `crossorigin` - CORS setting

#### `Video` - Video Player
```crystal
video = Elements::Video.new(
  src: "/videos/intro.mp4",
  width: "640",
  height: "360",
  controls: true,
  autoplay: false,
  loop: false,
  muted: false,
  preload: "metadata"
) do |v|
  # Fallback content
  v << "Your browser doesn't support HTML5 video."
end

# With multiple sources
video = Elements::Video.new(controls: true) do |v|
  v << Elements::Source.new(src: "/video.mp4", type: "video/mp4").render
  v << Elements::Source.new(src: "/video.webm", type: "video/webm").render
  v << "Your browser doesn't support HTML5 video."
end
```
**Attributes**: `src`, `width`, `height`, `controls`, `autoplay`, `loop`, `muted`, `preload`, `poster`

#### `Audio` - Audio Player
```crystal
audio = Elements::Audio.new(
  src: "/audio/music.mp3",
  controls: true,
  autoplay: false,
  loop: false
) do
  "Your browser doesn't support HTML5 audio."
end
```
**Attributes**: `src`, `controls`, `autoplay`, `loop`, `muted`, `preload`

#### `Source` - Media Source (Void)
```crystal
source = Elements::Source.new(
  src: "/video.mp4",
  type: "video/mp4"
)
```
**Attributes**: `src`, `type`, `media`, `srcset`, `sizes`

#### `Iframe` - Inline Frame
```crystal
iframe = Elements::Iframe.new(
  src: "https://example.com/embed",
  width: "800",
  height: "600",
  loading: "lazy",
  sandbox: "allow-scripts allow-same-origin",
  title: "Embedded content"
)
```
**Attributes**: `src`, `width`, `height`, `name`, `sandbox`, `allow`, `loading`, `referrerpolicy`, `title`

#### `Svg` - Scalable Vector Graphics
```crystal
svg = Elements::Svg.new(
  viewBox: "0 0 100 100",
  width: "100",
  height: "100",
  class: "icon"
) do
  '<path d="M10 10 H 90 V 90 H 10 Z" fill="blue"/>'
end
```
**Attributes**: `viewBox`, `width`, `height`, `preserveAspectRatio`, `xmlns`

#### `Canvas` - Graphics Canvas
```crystal
canvas = Elements::Canvas.new(
  id: "my-canvas",
  width: "400",
  height: "300"
) do
  "Canvas fallback content"
end
```
**Attributes**: `width`, `height`

---

### Interactive Elements

Elements for interactive UI components.

#### `Details` - Disclosure Widget
```crystal
details = Elements::Details.new(open: false) do |d|
  d << Elements::Summary.new { "Click to expand" }
  d << Elements::P.new { "Hidden content that appears when expanded." }
end
```
**Attributes**: `open` (boolean)

#### `Summary` - Details Summary
Always the first child of `<details>`.

```crystal
summary = Elements::Summary.new { "More Information" }
```

#### `Dialog` - Dialog Box
```crystal
dialog = Elements::Dialog.new(
  id: "my-dialog",
  open: false
) do |d|
  d << Elements::H2.new { "Dialog Title" }
  d << Elements::P.new { "Dialog content..." }
  d << Elements::Button.new(onclick: "closeDialog()") { "Close" }
end
```
**Attributes**: `open` (boolean)

---

### Void Elements

Self-closing elements (no content or closing tag).

```crystal
# Line break
br = Elements::Br.new

# Horizontal rule
hr = Elements::Hr.new(class: "divider")

# Image
img = Elements::Img.new(src: "/logo.png", alt: "Logo")

# Input
input = Elements::Input.text(name: "username")

# Link (in head)
link = Elements::Link.new(rel: "stylesheet", href: "/app.css")

# Meta
meta = Elements::Meta.new(charset: "UTF-8")

# Source (in video/audio)
source = Elements::Source.new(src: "/video.mp4", type: "video/mp4")

# All void elements automatically render as self-closing
html = img.render  # => <img src="/logo.png" alt="Logo">
```

**Complete list of void elements:**
- `Br`, `Hr`, `Img`, `Input`, `Link`, `Meta`, `Source`, `Area`, `Base`, `Col`, `Embed`, `Track`, `Wbr`

---

## Form-Specific Attributes

### Validation Attributes

```crystal
input = Elements::Input.text(
  required: true,           # Field is required
  pattern: "[A-Za-z]{3,}",  # Validation regex
  minlength: "3",           # Minimum length
  maxlength: "20",          # Maximum length
  min: "0",                 # Minimum value (number/date)
  max: "100",               # Maximum value (number/date)
  step: "5"                 # Value increment
)
```

### Autocomplete Hints

Common autocomplete values for better UX:

```crystal
# Name fields
Elements::Input.text(name: "fname", autocomplete: "given-name")
Elements::Input.text(name: "lname", autocomplete: "family-name")

# Email
Elements::Input.email(name: "email", autocomplete: "email")

# Phone
Elements::Input.tel(name: "phone", autocomplete: "tel")

# Address
Elements::Input.text(name: "address", autocomplete: "street-address")
Elements::Input.text(name: "city", autocomplete: "address-level2")
Elements::Input.text(name: "state", autocomplete: "address-level1")
Elements::Input.text(name: "zip", autocomplete: "postal-code")
Elements::Input.text(name: "country", autocomplete: "country-name")

# Payment
Elements::Input.text(name: "cc-name", autocomplete: "cc-name")
Elements::Input.text(name: "cc-number", autocomplete: "cc-number")
Elements::Input.text(name: "cc-exp", autocomplete: "cc-exp")
Elements::Input.text(name: "cc-csc", autocomplete: "cc-csc")

# Authentication
Elements::Input.text(name: "username", autocomplete: "username")
Elements::Input.password(name: "password", autocomplete: "current-password")
Elements::Input.password(name: "new-password", autocomplete: "new-password")
```

### Form Relationship

```crystal
# Button/input associated with form by ID
button = Elements::Button.new(
  type: "submit",
  form: "my-form-id"  # Submits this form even if button is outside it
) { "Submit" }

input = Elements::Input.text(
  name: "field",
  form: "my-form-id"  # Part of this form even if outside it
)
```

---

## Event Handler Attributes

All elements support event handler attributes:

### Mouse Events
```crystal
div = Elements::Div.new(
  onclick: "handleClick(event)",
  ondblclick: "handleDoubleClick()",
  onmouseenter: "handleMouseEnter()",
  onmouseleave: "handleMouseLeave()",
  onmousemove: "handleMouseMove(event)",
  onmousedown: "handleMouseDown()",
  onmouseup: "handleMouseUp()"
)
```

### Keyboard Events
```crystal
input = Elements::Input.text(
  onkeydown: "handleKeyDown(event)",
  onkeyup: "handleKeyUp(event)",
  onkeypress: "handleKeyPress(event)"
)
```

### Form Events
```crystal
form = Elements::Form.new(
  onsubmit: "return handleSubmit(event)",
  onreset: "handleReset()"
)

input = Elements::Input.text(
  oninput: "handleInput(event)",
  onchange: "handleChange(event)",
  onfocus: "handleFocus()",
  onblur: "handleBlur()"
)
```

### Focus Events
```crystal
input = Elements::Input.text(
  onfocus: "highlightField(this)",
  onblur: "validateField(this)",
  onfocusin: "handleFocusIn()",
  onfocusout: "handleFocusOut()"
)
```

### Media Events
```crystal
video = Elements::Video.new(
  onplay: "handlePlay()",
  onpause: "handlePause()",
  onended: "handleEnded()",
  onvolumechange: "handleVolumeChange()",
  ontimeupdate: "handleTimeUpdate(event)"
)
```

**Complete list:** `onclick`, `ondblclick`, `onmousedown`, `onmouseup`, `onmouseover`, `onmouseout`, `onmousemove`, `onmouseenter`, `onmouseleave`, `onkeydown`, `onkeyup`, `onkeypress`, `onfocus`, `onblur`, `onfocusin`, `onfocusout`, `oninput`, `onchange`, `onsubmit`, `onreset`, `onload`, `onerror`, `onresize`, `onscroll`

---

## Common Patterns

### Pattern 1: Building a Form

```crystal
form = Elements::Form.new(
  action: "/users",
  method: "post",
  class: "user-form"
) do |f|
  # Name field
  f << Elements::Div.new(class: "form-group") do |group|
    group << Elements::Label.new(for: "name") { "Name:" }
    group << Elements::Input.text(
      id: "name",
      name: "user[name]",
      required: true,
      placeholder: "Enter your name"
    ).render
  end

  # Email field
  f << Elements::Div.new(class: "form-group") do |group|
    group << Elements::Label.new(for: "email") { "Email:" }
    group << Elements::Input.email(
      id: "email",
      name: "user[email]",
      required: true,
      autocomplete: "email"
    ).render
  end

  # Password field
  f << Elements::Div.new(class: "form-group") do |group|
    group << Elements::Label.new(for: "password") { "Password:" }
    group << Elements::Input.password(
      id: "password",
      name: "user[password]",
      required: true,
      minlength: "8",
      autocomplete: "new-password"
    ).render
  end

  # Submit button
  f << Elements::Button.new(
    type: "submit",
    class: "btn btn-primary"
  ) { "Create Account" }
end
```

### Pattern 2: Building a Navigation Menu

```crystal
nav = Elements::Nav.new(class: "main-nav") do |n|
  n << Elements::Ul.new(class: "nav-list") do |ul|
    [
      {href: "/", text: "Home"},
      {href: "/about", text: "About"},
      {href: "/services", text: "Services"},
      {href: "/contact", text: "Contact"}
    ].each do |item|
      ul << Elements::Li.new(class: "nav-item") do
        Elements::A.new(
          href: item[:href],
          class: "nav-link"
        ) { item[:text] }.render
      end
    end
  end
end
```

### Pattern 3: Building a Data Table

```crystal
users = [
  {id: 1, name: "Alice", email: "alice@example.com"},
  {id: 2, name: "Bob", email: "bob@example.com"}
]

table = Elements::Table.new(class: "table table-striped") do |t|
  # Header
  t << Elements::Thead.new do |thead|
    thead << Elements::Tr.new do |tr|
      ["ID", "Name", "Email", "Actions"].each do |header|
        tr << Elements::Th.new { header }
      end
    end
  end

  # Body
  t << Elements::Tbody.new do |tbody|
    users.each do |user|
      tbody << Elements::Tr.new do |tr|
        tr << Elements::Td.new { user[:id].to_s }
        tr << Elements::Td.new { user[:name] }
        tr << Elements::Td.new { user[:email] }
        tr << Elements::Td.new do
          Elements::A.new(href: "/users/#{user[:id]}/edit") { "Edit" }.render
        end
      end
    end
  end
end
```

### Pattern 4: Building a Card Component

```crystal
def build_card(title, description, image_url, link_url)
  Elements::Div.new(
    class: "card",
    data_component: "card"
  ) do |card|
    # Image
    if image_url
      card << Elements::Img.new(
        src: image_url,
        alt: title,
        class: "card-image"
      ).render
    end

    # Content
    card << Elements::Div.new(class: "card-content") do |content|
      content << Elements::H3.new(class: "card-title") { title }
      content << Elements::P.new(class: "card-description") { description }

      # Link
      if link_url
        content << Elements::A.new(
          href: link_url,
          class: "card-link"
        ) { "Read More" }.render
      end
    end
  end
end
```

### Pattern 5: Conditional Rendering

```crystal
def render_user_profile(user, is_admin)
  Elements::Div.new(class: "user-profile") do |profile|
    profile << Elements::H2.new { user.name }
    profile << Elements::P.new { user.email }

    # Only show admin controls if user is admin
    if is_admin
      profile << Elements::Div.new(class: "admin-controls") do |controls|
        controls << Elements::Button.new { "Edit User" }.render
        controls << Elements::Button.new { "Delete User" }.render
      end
    end
  end
end
```

---

## HTML Escaping & Security

### When to Escape

**ALWAYS escape user-provided content:**

```crystal
# ✅ SAFE - Content is escaped
user_input = params["comment"]
p = Elements::P.new { escape_html(user_input) }

# ❌ DANGEROUS - XSS vulnerability
p = Elements::P.new { user_input }  # Don't do this!
```

### How Elements Handle Escaping

```crystal
# Element content is automatically escaped
div = Elements::Div.new { "<script>alert('XSS')</script>" }
div.render  # => <div>&lt;script&gt;alert('XSS')&lt;/script&gt;</div>

# Attributes are escaped too
div = Elements::Div.new(
  title: "<script>alert('XSS')</script>"
)
# => <div title="&lt;script&gt;alert('XSS')&lt;/script&gt;"></div>
```

### Raw HTML (Use with Extreme Caution)

```crystal
# Only use raw HTML for trusted, safe content
safe_html = "<strong>Bold text</strong>"
div = Elements::Div.new { raw(safe_html) }  # Renders HTML as-is

# NEVER use raw() with user input!
```

---

## Quick Troubleshooting

### "Element not rendering?"
- Check if it's a void element (no closing tag, no content)
- Verify all required attributes are provided
- Call `.render` to get HTML string

### "Attributes not showing up?"
- Use underscores in Crystal: `data_component` → `data-component`
- Boolean attributes: `required: true` not `required: "true"`
- Check attribute spelling

### "Content not appearing?"
- Container elements need content: `div << "content"` or block syntax
- Void elements don't have content (Br, Hr, Img, Input, etc.)
- Call `.render` on child elements when building strings

### "Validation errors?"
- Check required attributes (e.g., `src` for Img, `href` for Link)
- Ensure enum values are correct (`type`, `rel`, `method`, etc.)
- Verify numeric constraints (`min`, `max`, `minlength`, `maxlength`)

---

## Additional Resources

- **Main Component Guide**: `.claude/skills/asset-pipeline-components.md`
- **AssetPipeline Source**: `lib/asset_pipeline/`
- **Element Implementations**: `lib/asset_pipeline/src/components/elements/`
- **Reference Material**: `lib/asset_pipeline/component_system_reference_material/`

---

**Remember**: This reference covers all 87 HTML5 elements available in the AssetPipeline. When building components, start with the element that semantically matches your content, then compose larger structures from these building blocks.
