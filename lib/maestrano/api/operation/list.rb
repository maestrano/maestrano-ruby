module Maestrano
  module API
    module Operation
      module List
        module ClassMethods
          def all(filters={}, api_key=nil)
            response, api_key = Maestrano::API::Operation::Base.request(:get, url, api_key, filters)
            Util.convert_to_maestrano_object(response, api_key)
          end
        end

        def self.included(base)
          base.extend(ClassMethods)
        end
      end
    end
  end
end
