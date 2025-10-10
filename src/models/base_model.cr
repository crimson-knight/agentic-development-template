require "grant"

abstract class BaseModel < Grant::Base
  connection pg
end