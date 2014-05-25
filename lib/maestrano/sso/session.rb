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
        
        if self.uid.nil? || self.session_token.nil? || self.recheck.nil?
          $stderr.puts "WARNING: Maestrano session information missing. User will have to relogin"
        end 
      end
      
      def remote_check_required?
        if self.uid && self.session_token && self.recheck
          return (self.recheck <= Time.now)
        end
        return true
      end
      
      # Check remote maestrano session and update the
      # recheck attribute if the session is still valid
      # Return true if the session is still valid and
      # false otherwise
      def perform_remote_check
        # Get remote session info
        url = Maestrano::SSO.session_check_url(self.uid, self.session_token)
        begin
          response = RestClient.get(url)
          response = JSON.parse(response)
        rescue Exception => e
          response = {}
        end
        
        # Process response
        if response['valid'] && response['recheck']
          self.recheck = Time.iso8601(response['recheck'])
          return true
        end
        
        return false
      end
      
      def valid?
        if self.remote_check_required?
          if perform_remote_check
            self.session[:mno_session_recheck] = self.recheck.utc.iso8601
            return true
          else
            return false
          end
        end
        return true
      end
      
    end
  end
end