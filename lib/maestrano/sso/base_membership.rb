module Maestrano
  module SSO
    class BaseMembership
      attr_reader :user_uid,:group_uid,:role
      
      # Initializer
      # @param Maestrano::SAML::Response
      def initialize(saml_response)
        att = saml_response.attributes
        @user_uid = att['uid']
        @group_uid = att['group_uid']
        @role = att['group_role']
      end
      
      def to_hash
        {
          provider: 'maestrano',
          group_uid: self.group_uid,
          user_uid: self.user_uid,
          role: self.role
        }
      end
    end
  end
end
