# Controller Methods Validation

`before_action` and `after_action` accept a block as their only parameter.

```crystal
before_action { puts "Hello" }
after_action { puts "Goodbye" }
```

To use `current_user` in a controller method, you must set the `current_user` with an `if` statement as the condition.
```crystal
if current_user = get_current_user
  # The current_user is not `Nil`, we can safely use it, write any code requiring the `current_user` within this block.
end
```