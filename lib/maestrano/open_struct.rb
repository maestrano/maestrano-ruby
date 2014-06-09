module Maestrano

  # Extebd OpenStruct to include a 'attributes'
  # method
  class OpenStruct < ::OpenStruct
    # Return all object defined attributes
    def attributes
      (self.methods - self.class.new.methods).reject {|method| method =~ /=$/ }
    end
  end
end