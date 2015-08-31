module Maestrano
  module SSO
    include Preset
    class BaseUser
      attr_accessor :local_id
      attr_reader :sso_session,:sso_session_recheck,
        :group_uid,:group_role,:uid,:virtual_uid,:email,
        :virtual_email,:first_name, :last_name,:country, :company_name, :group_name
      
      # Initializer
      # @param Maestrano::SAML::Response
      def initialize(saml_response)
        att = saml_response.attributes
        @sso_session = att['mno_session']
        @sso_session_recheck = Time.iso8601(att['mno_session_recheck'])
        @group_uid = att['group_uid']
        @group_name = att['group_name']
        @group_role = att['group_role']
        @uid = att['uid']
        @virtual_uid = att['virtual_uid']
        @email = att['email']
        @virtual_email = att['virtual_email']
        @first_name = att['name']
        @last_name = att['surname']
        @country = att['country']
        @company_name = att['company_name']
      end
      
      def to_uid
        if Maestrano[Maestrano::SSO.preset].param('sso.creation_mode') == 'real'
          return self.uid
        else
          return self.virtual_uid
        end
      end
      
      def to_email
        if Maestrano[Maestrano::SSO.preset].param('sso.creation_mode') == 'real'
          return self.email
        else
          return self.virtual_email
        end
      end
      
      # Hash representation of the resource
      def to_hash
        {
          provider: 'maestrano',
          uid: self.to_uid,
          info: {
            email: self.to_email,
            first_name: self.first_name,
            last_name: self.last_name,
            country: self.country,
            company_name: self.company_name,
          },
          extra: {
            uid: self.uid,
            virtual_uid: self.virtual_uid,
            real_email: self.email,
            virtual_email: self.virtual_email,
            group: {
              uid: self.group_uid,
              name: self.group_name,
              role: self.group_role,
            },
            session: {
              uid: self.uid,
              token: self.sso_session,
              recheck: self.sso_session_recheck,
              group_uid: self.group_uid
            },
          }
        }
      end
    end
  end
end
