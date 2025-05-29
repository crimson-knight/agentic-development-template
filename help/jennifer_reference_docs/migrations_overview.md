# Overview

Migrations can manage the evolution of a schema used by a physical databases. It's a solution to the common problem of adding a field to make a new feature work in your local database, but being unsure of how to push that change to other developers and to the production server. With migrations, you can describe the transformations in self-contained classes that can be checked into version control systems and executed against another database that might be one, two, or five versions behind.

Example of a simple migration:
```crystal
class AddMainFlagToContacts < Jennifer::Migration::Base
  def up
    create_table(::contacts) do |t|
      t.string :name
      t.string :number, {:null => false}
    end
  end

  def down
    drop_table(::contacts)
  end
end
```

This migration will add a boolean flag to the contacts table and remove it if you're backing out of the migration. It shows how all migrations have two methods #up and #down that describes the transformations required to implement or remove the migration. These methods can consist of both the migration specific methods like #create_table and #drop_table, but may also contain regular Crystal code for generating data needed for the transformations.

By default each migration invocation (both #up and #down) are wrapped into a transaction but not all RDBMS support transactional schema changes (like MySQL). To specify additional mechanism to rollback after failed invocation you can chose 2 option: run reverse method (#down for #up and vise verse) or invoke special callback.

Using reverse direction:

```crystal
Jennifer::Config.configure do |conf|
  # ...
  conf.migration_failure_handler_method = "reverse_direction"
end

class AddMainFlagToContacts < Jennifer::Migration::Base
  def up
    change_table(::contacts) do |t|
      t.add_column :main, :bool, default: true
    end
  end

  def down
    change_table(::contacts) do |t|
      t.drop_column :main if column_exists?(:contacts, :main)
    end
  end
end
```

Using callbacks:

```crystal
Jennifer::Config.configure do |conf|
  # ...
  conf.migration_failure_handler_method = "callback"
end

class AddMainFlagToContacts < Jennifer::Migration::Base
  def up
    change_table(::contacts) do |t|
      t.add_column :main, :bool, default: true
    end
  end

  def after_up_failure
    change_table(::contacts) do |t|
      t.drop_column :main if column_exists?(:contacts, :main)
    end
  end

  def down
    change_table(::contacts) do |t|
      t.drop_column :main
    end
  end

  def after_down_failure
    change_table(::contacts) do |t|
      t.add_column :main, :bool, default: true unless column_exists?(:contacts, :main)
    end
  end
end
```

Such sort of behavior is useful when you have complex migration with several separate changes.

Also you can disable automatic transaction passing false to .with_transaction in a migration class body:

```crystal
class AddMainFlagToContacts < Jennifer::Migration::Base
  with_transaction false

  def up
    # ...
  end

  def down
    # ...
  end
end
```