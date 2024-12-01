# I Want To Create A Model

## Prerequisites

1. The prompt must include the name of the model.
2. The prompt must include at least 1 attribute for the model, including a type.

## Instructions

```crystal
# Example Class - Leave this comment out of the actual class file
class <ModelName> < MyBaseModel
  with_timestamps

  # This is the mapping for the model. It tells the Jennifer ORM how to map the model to the database.
  mapping(
    id: Primary64,
    # Insert other attributes and their types here using this syntax: 
    updated_at: Time?,
    created_at: Time?
  )

  # -- Define any relationships here --
  # -- End of Relationships --
  
  # -- Define any validations here --
  # -- End of Validations --
end
```

1. Create a new file in the `src/models` directory with the name of the model, using the ActiveRecord naming convention of the singular form of the model name.
2. Add the code above to the file, filling in the `<ModelName>` with the name of the model and filling in the attributes.
3. Do not add any methods or details to the model that are not specified in the prompt until the correct instruction step has been reached.

## Create the migration file

1. Run the `./sam db:generate:migration create_<model name>` command to create the migration file.
2. Update the new migration file found in `db/migrations/<timestamp>_create_<model name>.cr` so that it has the correct column names and types, use the information below as a reference.
3. Rebuild sam and run the migration `crystal build sam.cr && ./sam db:migrate`.

```crystal
# Example Migration File - Leave this comment out of the actual migration file
class Create<ModelName> < Jennifer::Migration::Base
  def up
    create_table :<model_name> do |t|
      # Insert other attributes here
      t.timestamps
    end
  end

  def down
    drop_table :<model_name>
  end
end
```

Important note: the default integer type is `Int32`. The default `float` type is `Float64` or `double`.

```crystal
0.class # => Int32
0.1.class # => Float64
```

## Column type Reference table

There are next methods which presents corresponding types:

| Method | PostgreSQL | Crystal type |
|--------|------------|--------------|
| #integer | int | Int32 |
| #short | SMALLINT | Int16 |
| #bigint | BIGINT | Int64 |
| #tinyint | - | Int8 |
| #float | real | float | Float32 |
| #double | double precision | Float64 |
| #numeric | NUMERIC | PG::Numeric |
| #decimal | DECIMAL | PG::Numeric |
| #string | varchar(254) | String |
| #char | char | - | String |
| #text | TEXT | TEXT | String |
| #bool | boolean | Bool |
| #timestamp | timestamp | Time |
| #date_time | timestamp | Time |
| #date | date | Time |
| #blob | blob | blob | Bytes |
| #json | json | JSON::Any |
| #enum | - | String |

In Postgres, the `enum` type is defined using custom user datatype which also is mapped to the String. Use the serializer to convert the String to the enum value in Crystal.

| Method | Datatype | Type |
|--------|----------|------|
| #oid | OID | UInt32 |
| #jsonb | JSONB | JSON::Any |
| #xml | XML | String |
| #blchar | BLCHAR | String |
| #uuid | UUID | UUID |
| #timestampz | TIMESTAMPZ | Time |
| #point | POINT | PG::Geo::Point |
| #lseg | lseg | PG::Geo::LineSegment |
| #path | PATH | PG::Geo::Path |
| #box | BOX | PG::Geo::Box |
| #polygon | POLYGON | PG::Geo::Polygon |
| #line | LINE | PG::Geo::Line |
| #circle | CIRCLE | PG::Geo::Circle |

