require 'set'
require 'json'

module SetJson
  def to_json(*options)
    to_a.to_json *options
  end
end

class Set
  prepend SetJson
end
