
### Validations method reference:

`#validates_acceptance` - This macro validates that a given field equals to true or be one of given values. By default "1" and true is recognized as accepted values.

```crystal
validates_acceptance :terms_of_service
validates_acceptance :terms_of_service, accept: ["true", "accept", "false", "decline"]
```

`#validates_confirmation` - This validation helps to check if confirmation field was filled with same value as specified. If confirmation is `nil` this validation will be skipped. To make comparison case insensitive specify second argument as true.

```crystal
class User < Jennifer::Model::Base
  mapping(
    # ...
    email: String?,
    address: String?
  )

  property email_confirmation : String?, address_confirmation : String?

  validates_confirmation :email
  validates_confirmation :address, case_insensitive: true
end
```

`#validates_exclusion` - This macro validates that the attribute's value aren't included in a given set. This could be any object which responds to `#includes?` method.

```crystal
validates_exclusion :code, in: %w(AA DD)
```

`#validates_format` - This macro validates that the attribute's value satisfies given regular expression.

```crystal
validates_format :street, /st\.|street/i
```

`#validates_inclusion` - This macro validates that the attribute's value are included in the set. This could be any object which responds to `#includes?` method.

```crystal
 validates_inclusion :code, in: Country::KNOWN_COUNTRIES
```

`#validates_length` - This macro validates the attribute's value length. There are a lot of options so constraint can be specified in different ways.
- `minimum` - length can't be less than specified one,
- `maximum` - length can't be greater than specified on,
- `in` - length must be included in given interval
- `is` - length must be same as specified

```crystal
validates_length :name, minimum: 2
validates_length :login, in: 4..16
validates_length :uid, is: 16
```

`#validates_numericality` - This macro validates if given number field satisfies specified constraints.
This macro accepts following constraints:
- `greater_than`
- `greater_than_or_equal_to`
- `equal_to`
- `less_than`
- `less_than_or_equal_to`
- `other_than`
- `odd`
- `even`


```crystal
validates_numericality :points, greater_than: 0
```


`#validates_presence` - This macro validates that attribute's value is not empty. It uses `#blank?` method, which behaves the same way as it does in Rails.

```crystal
validates_presence :name
```


