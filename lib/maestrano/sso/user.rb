module Maestrano
  module SSO
    module User
      def find_for_maestrano_auth(auth)
        # E.g with Rails
        # where(auth.slice(:provider, :uid)).first_or_create do |user|
        #   user.provider = auth[:provider]
        #   user.uid = auth[:uid]
        #   user.email = auth[:info][:email]
        #   user.name = auth[:info][:first_name]
        #   user.surname = auth[:info][:last_name]
        #   user.country = auth[:info][:country]
        #   user.company = auth[:info][:company_name]
        # end
        raise NoMethodError, "You need to override find_for_maestrano_auth in your #{self.class.name} model"
      end

      # Check whether the user is a maestrano one
      def maestrano?
        if self.respond_to?(:provider)
          return self.provider.to_s == 'maestrano'
        else
          raise NoMethodError, "You need to override maestrano? in your #{self.class.name} model"
        end
      end

      # Check whether the SSO session is still valid
      # or not
      def maestrano_session_valid?(session, preset = nil)
        Maestrano::SSO::Session[preset].new(session).valid?
      end
    end
  end
end
