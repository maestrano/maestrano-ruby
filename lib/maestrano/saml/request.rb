require "base64"
require "uuid"
require "zlib"
require "cgi"
require "rexml/document"
require "rexml/xpath"

module Maestrano
  module Saml
  include REXML
    class Request
      attr_accessor :settings, :params, :session
      
      def initialize(params = {}, session = {})
        self.settings = Maestrano::SSO.saml_settings
        self.params = params
        self.session = session
      end
      
      def redirect_url
        request_doc = create_authentication_xml_doc(settings)
        request_doc.context[:attribute_quote] = :quote if self.settings.double_quote_xml_attribute_values

        request = ""
        request_doc.write(request)

        request           = Zlib::Deflate.deflate(request, 9)[2..-5] if self.settings.compress_request
        base64_request    = Base64.encode64(request)
        encoded_request   = CGI.escape(base64_request)
        params_prefix     = (self.settings.idp_sso_target_url =~ /\?/) ? '&' : '?'
        request_params    = "#{params_prefix}SAMLRequest=#{encoded_request}"

        self.params.each_pair do |key, value|
          request_params << "&#{key.to_s}=#{CGI.escape(value.to_s)}"
        end
        
        if (request_params !~ /group_id=/) && (group_id = (self.session[:mno_group_uid] || self.session['mno_group_uid']))
          request_params << "&group_id=#{CGI.escape(group_id.to_s)}"
        end

        self.settings.idp_sso_target_url + request_params
      end

      def create_authentication_xml_doc(settings)
        uuid = "_" + UUID.new.generate
        time = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
        # Create AuthnRequest root element using REXML
        request_doc = REXML::Document.new

        root = request_doc.add_element "samlp:AuthnRequest", { "xmlns:samlp" => "urn:oasis:names:tc:SAML:2.0:protocol" }
        root.attributes['ID'] = uuid
        root.attributes['IssueInstant'] = time
        root.attributes['Version'] = "2.0"
        root.attributes['Destination'] = self.settings.idp_sso_target_url unless self.settings.idp_sso_target_url.nil?
        root.attributes['IsPassive'] = self.settings.passive unless self.settings.passive.nil?
        root.attributes['ProtocolBinding'] = self.settings.protocol_binding unless self.settings.protocol_binding.nil?

        # Conditionally defined elements based on settings
        if self.settings.assertion_consumer_service_url != nil
          root.attributes["AssertionConsumerServiceURL"] = self.settings.assertion_consumer_service_url
        end
        if self.settings.issuer != nil
          issuer = root.add_element "saml:Issuer", { "xmlns:saml" => "urn:oasis:names:tc:SAML:2.0:assertion" }
          issuer.text = self.settings.issuer
        end
        if self.settings.name_identifier_format != nil
          root.add_element "samlp:NameIDPolicy", {
              "xmlns:samlp" => "urn:oasis:names:tc:SAML:2.0:protocol",
              # Might want to make AllowCreate a setting?
              "AllowCreate" => "true",
              "Format" => self.settings.name_identifier_format
          }
        end

        # BUG fix here -- if an authn_context is defined, add the tags with an "exact"
        # match required for authentication to succeed.  If this is not defined,
        # the IdP will choose default rules for authentication.  (Shibboleth IdP)
        if self.settings.authn_context != nil
          requested_context = root.add_element "samlp:RequestedAuthnContext", {
            "xmlns:samlp" => "urn:oasis:names:tc:SAML:2.0:protocol",
            "Comparison" => "exact",
          }
          class_ref = requested_context.add_element "saml:AuthnContextClassRef", {
            "xmlns:saml" => "urn:oasis:names:tc:SAML:2.0:assertion",
          }
          class_ref.text = self.settings.authn_context
        end
        request_doc
      end

    end
  end
end
