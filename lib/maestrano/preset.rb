# When included, this module allows another module to be called setting a default preset
#
# Examples:
# Maestrano::Settings.new               # Uses 'default' preset
# Maestrano['mypreset']::Settings.new   # Uses 'mypreset'
module Maestrano
  module Preset
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def [](preset)
        define_singleton_method(:preset) { preset || 'default' }        
        self
      end

      def preset
        'default'
      end
    end
  end
end