# Single Table Inheritance

All users inherit from the `Persona` model and share the same table.

The 'type' column is used to determine the type of user and it's data type at runtime.

All records are going to share the same columns. You can overload the methods on the child model to add custom behavior to control how each type of user behaves.

**Each child model must have a `table_name` method that returns the name of the _parent class_ table.**