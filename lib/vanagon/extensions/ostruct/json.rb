require 'ostruct'
require 'json'

module OpenStructJson
  def to_json(*options)
    to_h.to_json options
  end
end

class OpenStruct
  prepend OpenStructJson
end
