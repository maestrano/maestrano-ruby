module Maestrano
  # Extend OpenStruct to include a 'attributes' method
  class OpenStruct < ::OpenStruct
    # Return all object defined attributes
    def attributes
      if self.respond_to?(:to_h)
        self.to_h.keys
      else
        (self.methods - self.class.new.methods).reject {|method| method =~ /=$/ }
      end
    end
  end
end
