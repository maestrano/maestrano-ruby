module Maestrano
  module SSO
    class BaseUser
      #============
      # Attributes
      #============
      attr_reader :sso_session,:sso_session_recheck,
        :group_uid,:group_role,:uid,:virtual_uid,:email,
        :virtual_email,:name,:country, :company_name
      
      #===========
      # Constants
      #===========
      SAML_ATTR_MAP = {sso_session: 'mno_sso_session', sso_session_recheck: 'mno_session_recheck' }
      
      # Initializer
      # @param Maestrano::SAML::Response
      def initialize(saml_response)
        att = saml_response.attributes
        @sso_session = att['mno_session']
        @sso_session_recheck = Time.iso8601(att['mno_session_recheck'])
        @group_uid = att['group_uid']
        @group_role = att['group_role']
        @uid = att['uid']
        @virtual_uid = att['virtual_uid']
        @email = att['email']
        @virtual_email = att['virtual_email']
        @name = att['name']
        @country = att['country']
        @company_name = att['company_name']
      end
    end
  end
end
