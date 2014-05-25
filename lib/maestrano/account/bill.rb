module Maestrano
  module Account
    class Bill < Maestrano::API::Resource
      include Maestrano::API::Operation::List
      include Maestrano::API::Operation::Create
      include Maestrano::API::Operation::Update

      def cancel(params={})
        response, api_key = Maestrano::API::Operation::Base.request(:delete, url, @api_key, params)
        refresh_from(response, api_key)
        self
      end
    end
  end
end