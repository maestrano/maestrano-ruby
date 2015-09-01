module Maestrano
  module Account
    class RecurringBill < Maestrano::API::Resource
      include Maestrano::API::Operation::List
      include Maestrano::API::Operation::Create

      def cancel
        response, api_token = Maestrano::API::Operation::Base[self.class.preset].request(:delete, url, @api_token)
        refresh_from(response, api_token)
        self
      end
    end
  end
end