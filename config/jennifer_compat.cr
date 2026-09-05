# Jennifer 0.13 passes symbolic validation messages to Wordsmith 0.5, whose
# humanize API accepts strings. Keep the locked dependency versions reproducible.
module Wordsmith::Inflector
  def self.humanize(value : Symbol)
    humanize(value.to_s)
  end
end
