module Maestrano
  module API
    module Operation
      module Delete
        def delete(params = {})
          response, api_key = Maestrano::API::Operation::Base.request(:delete, url, @api_key, params)
          refresh_from(response, api_key)
          self
        end
      end
    end
  end
end