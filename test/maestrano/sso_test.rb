require File.expand_path('../../test_helper', __FILE__)

module Maestrano
  class SSOTest < Test::Unit::TestCase
    include SamlTestHelper
  
    setup do
      Maestrano.config = nil
      Maestrano.configure { |config| config.environment = 'production' }
    end
  
    should "return the right init_url" do
      assert Maestrano::SSO.init_url == "http://localhost:3000/maestrano/auth/saml/init"
    end
  
    should "return the right consume_url" do
      assert Maestrano::SSO.consume_url == "http://localhost:3000/maestrano/auth/saml/consume"
    end
  
    should "return the right logout_url" do
      assert Maestrano::SSO.logout_url == "https://maestrano.com/app_logout"
    end
  
    should "return the right unauthorized_url" do
      assert Maestrano::SSO.unauthorized_url == "https://maestrano.com/app_access_unauthorized"
    end
  
    should "return the right idp_url" do
      assert Maestrano::SSO.idp_url == "https://maestrano.com/api/v1/auth/saml"
    end
  
    should "return the right session_check_url" do
      assert Maestrano::SSO.session_check_url('usr-1','f9ds8fdg7f89') == "https://maestrano.com/api/v1/auth/saml/usr-1?session=f9ds8fdg7f89"
    end
  
    should "return the right enabled parameter" do
      assert Maestrano::SSO.enabled? == !!Maestrano.param('sso_enabled')
    end
  
    should "return the right saml_settings" do
      settings = Maestrano::SSO.saml_settings
      assert settings.assertion_consumer_service_url == Maestrano::SSO.consume_url
      assert settings.issuer == Maestrano.param('app_host')
      assert settings.idp_sso_target_url == Maestrano::SSO.idp_url
      assert settings.idp_cert_fingerprint == Maestrano.param('sso_x509_fingerprint')
      assert settings.name_identifier_format == Maestrano.param('sso_name_id_format')
    end
  
    should "build the right saml request" do
      request = mock('request')
      Maestrano::Saml::Request.stubs(:new).with(group_id: "cld-3").returns(request)
      assert Maestrano::SSO.build_request(group_id: "cld-3") == request
    end
  
    should "build the right saml response" do
      response = mock('response')
      Maestrano::Saml::Response.stubs(:new).with(response_document).returns(response)
      response = Maestrano::SSO.build_response(response_document)
      assert Maestrano::SSO.build_response(response_document) == response
    end
  
    should "set the session correctly" do
      session = {}
      auth = {
        extra: {
          session: {
            uid: 'usr-1',
            token: '15fg6d',
            recheck: Time.now,
            group_uid: 'cld-3'
          }
        }
      }
      Maestrano::SSO.set_session(session,auth)
      assert_equal session[:mno_uid], auth[:extra][:session][:uid]
      assert_equal session[:mno_session], auth[:extra][:session][:token]
      assert_equal session[:mno_session_recheck], auth[:extra][:session][:recheck].utc.iso8601
      assert_equal session[:mno_group_uid], auth[:extra][:session][:group_uid]
    end
  end
end