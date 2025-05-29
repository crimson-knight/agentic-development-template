# Jennifer Migration - CreateTable Overview

## Description

Component responsible for creating a new table based on specified columns and properties.

## Usage Example

```crystal
create_table(:contacts) do |t|
  t.string :name, {:size => 30}
  t.integer :age
  t.integer :tags, {:array => true}
  t.decimal :ballance
  t.field :gender, :gender_enum
  t.timestamps true
end
```

**Defined in:** `jennifer/migration/table_builder/create_table.cr`

## Instance Methods

### Basic Column Types

#### `#string(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `string` with given options.

#### `#integer(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `integer` with given options.

#### `#bigint(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `bigint` with given options.

#### `#short(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `short` with given options.

#### `#tinyint(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `tinyint` with given options.

#### `#bool(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `bool` with given options.

### Numeric Types

#### `#float(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `float` with given options.

#### `#double(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `double` with given options.

#### `#decimal(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `decimal` with given options.

#### `#numeric(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `numeric` with given options.

### Text Types

#### `#text(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `text` with given options.

#### `#varchar(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `varchar` with given options.

#### `#char(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `char` with given options.

#### `#blchar(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `blchar` with given options.

### Date and Time Types

#### `#date(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `date` with given options.

#### `#date_time(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `date_time` with given options.

#### `#timestamp(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `timestamp` with given options.

#### `#timestamptz(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `timestamptz` with given options.

#### `#timestamps(null : Bool = false)`

Defines `created_at` and `updated_at` timestamp fields.

### JSON Types

#### `#json(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `json` with given options.

#### `#jsonb(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `jsonb` with given options.

### Binary Types

#### `#blob(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `blob` with given options.

#### `#bytea(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `bytea` with given options.

### UUID and OID Types

#### `#uuid(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `uuid` with given options.

#### `#oid(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `oid` with given options.

### Geometric Types

#### `#point(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `point` with given options.

#### `#line(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `line` with given options.

#### `#lseg(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `lseg` with given options.

#### `#box(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `box` with given options.

#### `#path(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `path` with given options.

#### `#polygon(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `polygon` with given options.

#### `#circle(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `circle` with given options.

### XML Type

#### `#xml(name : String | Symbol, options = DbOptions.new)`

Defines new column `name` of type `xml` with given options.

### Special Column Types

#### `#field(name : String | Symbol, type : Symbol | String, options : Hash(Symbol, AAllowedTypes) = DbOptions.new)`

Defines field `name` of type `type` with given options.

#### `#column(name, type, options = DbOptions.new)`

Alias for `#field`.

#### `#enum(name : String | Symbol, values : Array(String), options : Hash(Symbol, AAllowedTypes) = DbOptions.new)`

Defines new enum column `name` with given options.

#### `#generated(name : String | Symbol, type : Symbol | String, as_query : String, options : Hash(Symbol, AAllowedTypes) = DbOptions.new)`

Defines generated column `name` of type `type` that will use `as_query` expression to generate.

### Index Operations

#### `#index(fields : Array(Symbol), type : Symbol | Nil = nil, name : String | Nil = nil, lengths : Hash(Symbol, Int32) = {} of Symbol => Int32, orders : Hash(Symbol, Symbol) = {} of Symbol => Symbol)`

Adds index with multiple fields.

#### `#index(field : Symbol, type : Symbol | Nil = nil, name : String | Nil = nil, length : Int32 | Nil = nil, order : Symbol | Nil = nil)`

Adds index with single field.

### Foreign Key and Reference Operations

#### `#foreign_key(to_table : String | Symbol, column = nil, primary_key = nil, name = nil, *, on_update : Symbol = DEFAULT_ON_EVENT_ACTION, on_delete : Symbol = DEFAULT_ON_EVENT_ACTION)`

Creates a foreign key constraint to `to_table` table.

#### `#reference(name, type : Symbol = :bigint, options : Hash(Symbol, AAllowedTypes) = DbOptions.new)`

Adds a reference.

### Utility Methods

#### `#fields : Hash(String, Hash(Symbol, Array(Bool | Float32 | Float64 | Int32 | Int64 | JSON::Any | String | Symbol | Nil) | Bool | Float32 | Float64 | Int32 | Int64 | JSON::Any | String | Symbol | Nil))`

Returns hash of defined fields with their properties.

#### `#explain`

Returns string presentation of invoked changes.

#### `#process`

Invokes current command.

## Inherited Methods

**From class `Jennifer::Migration::TableBuilder::Base`:**

- `adapter`
- `column_exists?`
- `explain`
- `index_exists?`
- `name`
- `process`
- `process_commands`
- `schema_processor`
- `table_exists?`