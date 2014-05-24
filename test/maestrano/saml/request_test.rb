require File.expand_path('../../../test_helper', __FILE__)

class RequestTest < Test::Unit::TestCase

  context "Request" do
    should "create the deflated SAMLRequest URL parameter" do
      settings = Maestrano::Saml::Settings.new
      settings.idp_sso_target_url = "http://example.com"
      auth_url = Maestrano::Saml::Request.new.create(settings)
      assert auth_url =~ /^http:\/\/example\.com\?SAMLRequest=/
      payload  = CGI.unescape(auth_url.split("=").last)
      decoded  = Base64.decode64(payload)

      zstream  = Zlib::Inflate.new(-Zlib::MAX_WBITS)
      inflated = zstream.inflate(decoded)
      zstream.finish
      zstream.close

      assert_match /^<samlp:AuthnRequest/, inflated
    end

    should "create the deflated SAMLRequest URL parameter including the Destination" do
      settings = Maestrano::Saml::Settings.new
      settings.idp_sso_target_url = "http://example.com"
      auth_url = Maestrano::Saml::Request.new.create(settings)
      payload  = CGI.unescape(auth_url.split("=").last)
      decoded  = Base64.decode64(payload)

      zstream  = Zlib::Inflate.new(-Zlib::MAX_WBITS)
      inflated = zstream.inflate(decoded)
      zstream.finish
      zstream.close

      assert_match /<samlp:AuthnRequest[^<]* Destination='http:\/\/example.com'/, inflated
    end

    should "create the SAMLRequest URL parameter without deflating" do
      settings = Maestrano::Saml::Settings.new
      settings.compress_request = false
      settings.idp_sso_target_url = "http://example.com"
      auth_url = Maestrano::Saml::Request.new.create(settings)
      assert auth_url =~ /^http:\/\/example\.com\?SAMLRequest=/
      payload  = CGI.unescape(auth_url.split("=").last)
      decoded  = Base64.decode64(payload)

      assert_match /^<samlp:AuthnRequest/, decoded
    end

    should "create the SAMLRequest URL parameter with IsPassive" do
      settings = Maestrano::Saml::Settings.new
      settings.idp_sso_target_url = "http://example.com"
      settings.passive = true
      auth_url = Maestrano::Saml::Request.new.create(settings)
      assert auth_url =~ /^http:\/\/example\.com\?SAMLRequest=/
      payload  = CGI.unescape(auth_url.split("=").last)
      decoded  = Base64.decode64(payload)

      zstream  = Zlib::Inflate.new(-Zlib::MAX_WBITS)
      inflated = zstream.inflate(decoded)
      zstream.finish
      zstream.close

      assert_match /<samlp:AuthnRequest[^<]* IsPassive='true'/, inflated
    end

    should "create the SAMLRequest URL parameter with ProtocolBinding" do
      settings = Maestrano::Saml::Settings.new
      settings.idp_sso_target_url = "http://example.com"
      settings.protocol_binding = 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST'
      auth_url = Maestrano::Saml::Request.new.create(settings)
      assert auth_url =~ /^http:\/\/example\.com\?SAMLRequest=/
      payload  = CGI.unescape(auth_url.split("=").last)
      decoded  = Base64.decode64(payload)

      zstream  = Zlib::Inflate.new(-Zlib::MAX_WBITS)
      inflated = zstream.inflate(decoded)
      zstream.finish
      zstream.close

      assert_match /<samlp:AuthnRequest[^<]* ProtocolBinding='urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST'/, inflated
    end

    should "accept extra parameters" do
      settings = Maestrano::Saml::Settings.new
      settings.idp_sso_target_url = "http://example.com"

      auth_url = Maestrano::Saml::Request.new.create(settings, { :hello => "there" })
      assert auth_url =~ /&hello=there$/

      auth_url = Maestrano::Saml::Request.new.create(settings, { :hello => nil })
      assert auth_url =~ /&hello=$/
    end

    context "when the target url doesn't contain a query string" do
      should "create the SAMLRequest parameter correctly" do
        settings = Maestrano::Saml::Settings.new
        settings.idp_sso_target_url = "http://example.com"

        auth_url = Maestrano::Saml::Request.new.create(settings)
        assert auth_url =~ /^http:\/\/example.com\?SAMLRequest/
      end
    end

    context "when the target url contains a query string" do
      should "create the SAMLRequest parameter correctly" do
        settings = Maestrano::Saml::Settings.new
        settings.idp_sso_target_url = "http://example.com?field=value"

        auth_url = Maestrano::Saml::Request.new.create(settings)
        assert auth_url =~ /^http:\/\/example.com\?field=value&SAMLRequest/
      end
    end
  end
end
