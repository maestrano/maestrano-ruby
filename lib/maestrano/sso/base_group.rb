module Maestrano
  module SSO
    class BaseGroup
      attr_accessor :local_id
      attr_reader :uid, :company_name, :free_trial_end_at, :has_credit_card, :name, :org_uid, :email, :city,
        :country, :timezone, :currency


      # Initializer
      # @param Maestrano::SAML::Response
      def initialize(saml_response)
        att = saml_response.attributes
        @uid = att['group_uid']
        @has_credit_card = (att['group_has_credit_card'] == 'true')
        @free_trial_end_at = Time.iso8601(att['group_end_free_trial'])
        @company_name = att['company_name']
        @name = att['group_name']
        @org_uid = att['group_org_uid']
        @email = att['group_email']
        @city = att['group_city']
        @timezone = att['group_timezone']
        @currency = att['group_currency']
        @country = att['country']
      end

      def to_hash
        {
          provider: 'maestrano',
          uid: self.uid,
          info: {
            free_trial_end_at: self.free_trial_end_at,
            company_name: self.company_name,
            has_credit_card: self.has_credit_card,
            name: self.name,
            org_uid: self.org_uid,
            email: self.email,
            city: self.city,
            country: self.country,
            timezone: self.timezone,
            currency: self.currency
          },
          extra: {}
        }
      end
    end
  end
end
