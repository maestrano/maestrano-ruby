module Maestrano
  module Account
    class RecurringBill < Maestrano::API::Resource
      include Maestrano::API::Operation::List
      include Maestrano::API::Operation::Create

      def cancel
        response, api_key = Maestrano::API::Operation::Base.request(:delete, url, @api_key)
        refresh_from(response, api_key)
        self
      end
    end
  end
end