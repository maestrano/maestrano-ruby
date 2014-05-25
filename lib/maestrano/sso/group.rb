module Maestrano
  module SSO
    module Group
      def find_for_maestrano_auth(auth)
        # E.g with Rails
        # where(auth.slice(:provider, :uid)).first_or_create do |group|
        #   group.provider = auth[:provider]
        #   group.uid = auth[:uid]
        #   group.name = (auth[:info][:company_name] || 'Your Group')
        #   group.country = auth[:info][:country]
        # end
        raise NoMethodError, "You need to override find_for_maestrano_auth in your #{self.class.name} model"
      end
      
      def maestrano?
        if self.respond_to?(:provider)
          return self.provider.to_s == 'maestrano'
        else
          raise NoMethodError, "You need to override maestrano? in your #{self.class.name} model"
        end
      end
    end
  end
end