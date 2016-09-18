module Maestrano
  module SSO
    include Preset

    # Return the saml_settings based on
    # Maestrano configuration
    def self.saml_settings
      settings = Maestrano::Saml::Settings.new
      settings.assertion_consumer_service_url = self.consume_url
      settings.issuer                         = Maestrano[preset].param('api.id')
      settings.idp_sso_target_url             = self.idp_url
      settings.idp_cert                       = Maestrano[preset].param('sso.x509_certificate')
      settings.idp_cert_fingerprint           = Maestrano[preset].param('sso.x509_fingerprint')
      settings.name_identifier_format         = Maestrano[preset].param('sso.name_id_format')
      settings
    end

    # Build a new SAML Request
    def self.build_request(get_params = {})
      Maestrano::Saml::Request[preset].new(get_params)
    end

    # Build a new SAML response
    def self.build_response(saml_post_param)
      Maestrano::Saml::Response[preset].new(saml_post_param)
    end

    def self.enabled?
      !!Maestrano[preset].param('sso.enabled')
    end

    def self.init_url
      host = Maestrano[preset].param('sso.idm')
      path = Maestrano[preset].param('sso.init_path')
      return "#{host}#{path}"
    end

    def self.consume_url
      host = Maestrano[preset].param('sso.idm')
      path = Maestrano[preset].param('sso.consume_path')
      return "#{host}#{path}"
    end

    def self.logout_url
      host = Maestrano[preset].param('api.host')
      path = '/app_logout'
      return "#{host}#{path}"
    end

    def self.unauthorized_url
      host = Maestrano[preset].param('api.host')
      path = '/app_access_unauthorized'
      return "#{host}#{path}";
    end

    def self.idp_url
      host = Maestrano[preset].param('api.host')
      api_base = Maestrano[preset].param('api.base')
      endpoint = 'auth/saml'
      return "#{host}#{api_base}#{endpoint}"
    end

    def self.session_check_url(user_uid,sso_session)
      host = Maestrano[preset].param('api.host')
      api_base = Maestrano[preset].param('api.base')
      endpoint = 'auth/saml'
      return URI.escape("#{host}#{api_base}#{endpoint}/#{user_uid}?session=#{sso_session}")
    end

    # Set maestrano attributes in session
    # Takes the BaseUser hash representation and current session
    # in arguments
    def self.set_session(session, auth)
      Maestrano::SSO::Session[preset].from_user_auth_hash(session,auth).save
    end

    # Destroy the maestrano session in http session
    def self.clear_session(session)
      session.delete(:maestrano)
      session.delete('maestrano')
    end

    # Metaclass definitions
    class << self
      alias_method :unset_session, :clear_session
    end
  end
end
