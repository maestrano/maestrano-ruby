module Maestrano
  module API
    module Operation
      module List
        module ClassMethods
          def all(filters={}, api_token=nil)
            response, api_token = Maestrano::API::Operation::Base.request(:get, url, api_token, filters)
            Util.convert_to_maestrano_object(response, api_token)
          end
        end

        def self.included(base)
          base.extend(ClassMethods)
        end
      end
    end
  end
end
