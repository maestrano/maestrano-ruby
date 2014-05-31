module Maestrano
  module API
    module Operation
      module Create
        module ClassMethods
          def create(params={}, api_token=nil)
            response, api_token = Maestrano::API::Operation::Base.request(:post, self.url, api_token, params)
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
