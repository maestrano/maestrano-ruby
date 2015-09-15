module Maestrano
  module API
    module Operation
      module Delete
        def delete(params = {})
          response, api_token = Maestrano::API::Operation::Base[self.class.preset].request(:delete, url, @api_token, params)
          refresh_from(response, api_token)
          self
        end
      end
    end
  end
end