module Maestrano
  module SSO
    class Session
      attr_accessor :session, :uid, :session_token, :recheck
      
      def initialize(session)
        self.session = session
        self.uid = (self.session['mno_uid'] || self.session[:mno_uid])
        self.session_token = (self.session['mno_session'] || self.session[:mno_session])
        if recheck = (self.session['mno_session_recheck'] || self.session[:mno_session_recheck])
          self.recheck = Time.iso8601(recheck)
        end
      end
    end
  end
end