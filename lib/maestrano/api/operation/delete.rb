module Maestrano
  module API
    module Operation
      module Delete
        def delete(params = {})
          response, api_token = Maestrano::API::Operation::Base.request(:delete, url, @api_token, params)
          refresh_from(response, api_token)
          self
        end
      end
    end
  end
end