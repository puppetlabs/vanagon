# This is bad, and I feel bad. This will let you append
# broadly useful Hash and JSON casting on any class that
# includes it. But it's pretty naive, in that it just turns
# attributes names into keys while retaining their
# associated values.
module HashableAttributes
  # @return [Hash] Converts an object to a hash with keys representing
  #   each attribute (as symbols) and their corresponding values
  def to_hash
    instance_variables.each_with_object({}) do |var, hash|
      hash[var.to_s.delete("@")] = instance_variable_get(var)
    end
  end
  alias_method :to_h, :to_hash

  def to_json(*options)
    to_hash.to_json options
  end
end

# Vanagon classes generally don't implement JSON or Hash functionality
# so those need to be monkey-patched for useful inspection.
class Vanagon
  class Platform
    include HashableAttributes
  end

  class Common
    class Pathname
      include HashableAttributes
    end
  end

  class Component
    include HashableAttributes
  end

  class Patch
    include HashableAttributes
  end
end
