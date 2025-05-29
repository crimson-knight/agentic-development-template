# Jennifer Migration - ChangeTable Overview

## Description

Component responsible for altering existing table based on specified columns and properties.

## Usage Example

```crystal
change_table(:contacts) do |t|
  t.rename_table :users
  t.add_column :name, :string, {:size => 30}
  t.drop_column :age
end
```

**Defined in:** `jennifer/migration/table_builder/change_table.cr`

## Constructors

### `.new(adapter, name)`

Creates a new ChangeTable instance.

## Instance Methods

### Column Operations

#### `#add_column(name : String | Symbol, type : Symbol | Nil = nil, options : Hash(Symbol, AAllowedTypes) = DbOptions.new)`

Defines new column `name` of `type` with given `options`.

#### `#change_column(name : String | Symbol, type : Symbol | Nil = nil, options : Hash(Symbol, AAllowedTypes) = DbOptions.new)`

Changes the column's definition according to the new options.

#### `#drop_column(name : String | Symbol)`

Drops column with given name.

#### `#drop_columns : Array(String)`

Returns array of dropped columns.

#### `#changed_columns : Hash(String, Hash(Symbol, Array(Bool | Float32 | Float64 | Int32 | Int64 | JSON::Any | String | Symbol | Nil) | Bool | Float32 | Float64 | Int32 | Int64 | JSON::Any | String | Symbol | Nil))`

Returns hash of changed columns with their properties.

### Index Operations

#### `#add_index(fields : Array(Symbol), type : Symbol | Nil = nil, name : String | Nil = nil, lengths : Hash(Symbol, Int32) = {} of Symbol => Int32, orders : Hash(Symbol, Symbol) = {} of Symbol => Symbol)`

Adds new index with multiple fields.

#### `#add_index(field : Symbol, type : Symbol | Nil = nil, name : String | Nil = nil, length : Int32 | Nil = nil, order : Symbol | Nil = nil)`

Adds new index with single field.

#### `#drop_index(fields : Array(Symbol) = [] of Symbol, name : String | Nil = nil)`

Drops the index from the table using multiple fields.

#### `#drop_index(field : Symbol | Nil = nil, name : String | Nil = nil)`

Drops the index from the table using single field.

### Foreign Key Operations

#### `#add_foreign_key(to_table : String | Symbol, column = nil, primary_key = nil, name = nil, *, on_update : Symbol = DEFAULT_ON_EVENT_ACTION, on_delete : Symbol = DEFAULT_ON_EVENT_ACTION)`

Creates a foreign key constraint to `to_table` table.

#### `#drop_foreign_key(to_table : String | Symbol, column = nil, name = nil)`

Drops foreign key of `to_table`.

### Reference Operations

#### `#add_reference(name, type : Symbol = :bigint, options : Hash(Symbol, AAllowedTypes) = DbOptions.new)`

Adds a reference.

#### `#drop_reference(name, options : Hash(Symbol, AAllowedTypes) = DbOptions.new)`

Drops the reference.

### Timestamp Operations

#### `#add_timestamps(null : Bool = false)`

Add `created_at` and `updated_at` timestamp columns.

### Table Operations

#### `#rename_table(new_name : String | Symbol)`

Renames table to the given `new_name`.

#### `#new_table_name : String`

Returns the new table name.

### Utility Methods

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