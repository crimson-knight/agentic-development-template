## Table name

By default model determines related table name by underscoring and pluralizing own class name. In the case when model is define under some namespace, it's underscored name is considered as table name prefix.

```crystal
User.table_name # "users"
API::Admin::User.table_name # "api_admin_users"
```

To override table name prefix define own `.table_prefix`

```crystal
module Admin
  class Base < Jennifer::Model::Base
    def self.table_prefix
      "private_"
    end
  end

  class User < Base
    mapping(id: Primary32)
  end
end

Admin::User.table_name # "private_users"
```

> As you see `.table_prefix` should return `"_"` at the end to keep naming across application consistent.

> Also to prevent adding table prefix at all - return `nil`.

To override table name just call `.table_name`:

```crystal
class User < Jennifer::Model::Base
  table_name :posts
  # ...
end

class Admin::User < Jennifer::Model::Base
  table_name "users"
end

User.table_name # "posts"
Admin::User.table_name # "users"
```

> `.table_name` accepts table name that already includes prefix.

