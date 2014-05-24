module Maestrano
  module SSO
    class BaseGroup
      attr_accessor :local_id
      attr_reader :uid,:country, :company_name, :free_trial_end_at
      
      # Initializer
      # @param Maestrano::SAML::Response
      def initialize(saml_response)
        att = saml_response.attributes
        @uid = att['group_uid']
        @country = att['country']
        @free_trial_end_at = Time.iso8601(att['group_end_free_trial'])
        @company_name = att['company_name']
      end
    end
  end
end
