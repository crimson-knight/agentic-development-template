# Create A Model

## Prerequisites

- Required: The name of the model, this could be a singular word, or phrase.
- Optional: A list of relationships that the model has with other existing models
  - Model relationships need to be described using phrases from the Active Record Associations design pattern.
- Optional: A list of attributes that the model has, including the attribute name and a description of the attributes data type.

Review the information that you have been provided to ensure it includes all of the required information.
Review the information that you have been provided to ensure it includes all of the optional information.

If there is any missing information or vague information, prompt the user for the missing information before proceeding.

Check the database.yml file to determine which database is being used.

## Steps

1. Create a new model file in the `src/models` directory, using the following template

```crystal
# src/models/{{singular_model_name}}.cr
class {{singular_model_name}} < BaseModel
  with_timestamps

  mapping(
    id: Primary64, # Always uses a BigInt primary key
    # Add each attribute here, using the following syntax:
    # attribute_name: Type,
    # or add attribute details with this syntax:
    # attribute_name: {type: Type, options},
    name: String,
    gender: {type: String?, default: "male"},
    age: {type: Int32, default: 10},
    description: String?,
    created_at: Time?,
    updated_at: Time | Nil # Alternative syntax for `Time?`, prefer using the `Time?` syntax
  )

  # Add any relationships here
  has_many :addresses, Address
  has_and_belongs_to_many :countries, Country
  has_one :passport, Passport

  # Add any validations here
  validates_inclusion :age, 13..75 
  validates_length :name, minimum: 1, maximum: 15
  validates_with_method :name_check

  def name_check
    if @description && @description.not_nil!.size > 10
      errors.add(:description, "Too large description")
    end
  end
end
```

| Options for `mapping` each attribute | description |
|-----        |-----|
| :type       | crystal data type |
| :primary    | mark field as primary key (default: `false`) |
| :null       | allows field to be nil (default: `false` for all fields except primary key) |
| :default    | default value which will be used during object initialization |
| :column     | database column name associated with this attribute (defaults to the attributes name) |
| :getter     | if getter should be created (default: `true`) |
| :setter     | if setter should be created (default: `true`) |
| :virtual    | mark field as virtual - will not be stored and retrieved from DB |
| :generated  | field represents generated column (is only read from the DB) |
| :converter  | class/module/object that is used to serialize/deserialize field |
| :auto       | indicate whether primary field is autoincrementable (by default true for Int32 and Int64) |

2. Create the migration file in the `db/migrations` directory, using the following template
  2a. see if the `sam` binary exists in the project root, if not, compile it with `crystal build sam.cr`
  2b. run `sam generate migration {{model_name_with_underscores}}`

In the newly created migration file, use the following template to make the necessary changes.

```crystal
# db/migrations/timestamp_your_underscored_migration_name.cr
class {{underscored_migration_name}} < BaseMigration
  def up
    # Add the migration code here
    create_table :{{underscored_model_name}} do |t|
      t.string :name
      t.string :gender
      t.integer :age
      t.text :description
      t.timestamps

      # This syntax creates a field contact_id with BigInt type, allows null values and creates foreign key
      # t.reference :contact
      t.reference {{symbolized_underscored_model_relationship_name}}
    end
  end

  def down
    # Add the migration code here
  end
end
```

Method	PostgreSQL	MySql	Crystal type
#integer	int	int	Int32
#short	SMALLINT	SMALLINT	Int16
#bigint	BIGINT	BIGINT	Int64
#tinyint	-	TINYINT	Int8
#float	real	float	Float32
#double	double precision	double	Float64
#numeric	NUMERIC	-	PG::Numeric
#decimal	DECIMAL	DECIMAL	PG::Numeric (pg); Float64 (mysql)
#string	varchar(254)	varchar(254)	String
#char	char	-	String
#text	TEXT	TEXT	String
#bool	boolean	bool	Bool
#timestamp	timestamp	datetime	Time
#date_time	timestamp	datetime	Time
#date	date	date	Time
#blob	blob	blob	Bytes
#json	json	json	JSON::Any
#enum	-	ENUM	String

PostgreSQL specific datatypes:

Method	Datatype	Type
#oid	OID	UInt32
#jsonb	JSONB	JSON::Any
#xml	XML	String
#blchar	BLCHAR	String
#uuid	UUID	UUID
#timestampz	TIMESTAMPZ	Time
#point	POINT	PG::Geo::Point
#lseg	lseg	PG::Geo::LineSegment
#path	PATH	PG::Geo::Path
#box	BOX	PG::Geo::Box
#polygon	POLYGON	PG::Geo::Polygon
#line	LINE	PG::Geo::Line
#circle	CIRCLE	PG::Geo::Circle

On Postgres only, create a materialized view:

```crystal
# create_materialized_view("materialized_view_name", query)
create_materialized_view("female_contacts", Contact.all.where { _gender == "female" })
```

To execute plain SQL within the migration, use the `exec` method:
```crystal
exec("ALTER TABLE addresses CHANGE street st VARCHAR(20)")
```

Enums
Now enums are supported as well but each adapter has own implementation.

```crystal
# Example for MySQL
create_table(:contacts) do |t|
  t.enum(:gender, ["male", "female"])
end
```

For Postgres you need to create enum first:

```crystal
create_enum(:gender_enum, ["male", "female"])

create_table(:contacts) do |t|
  t.string :name, {:size => 30}
  t.integer :age
  t.field :gender, :gender_enum
  t.timestamps
end

change_enum(:gender_enum, {:add_values => ["unknown"]})
change_enum(:gender_enum, {:rename_values => ["unknown", "other"]})
change_enum(:gender_enum, {:remove_values => ["other"]})
```

3. Recompile `sam` and run the migrations

```bash
crystal build sam.cr && ./sam db:migrate
```
