require File.expand_path('../../test_helper', __FILE__)

module Maestrano
  class SSOTest < Test::Unit::TestCase
    include SamlTestHelper
  
    context 'without preset' do
      setup do
        Maestrano.configs = nil
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
        assert Maestrano::SSO.enabled? == !!Maestrano.param('sso.enabled')
      end
    
      should "return the right saml_settings" do
        settings = Maestrano::SSO.saml_settings
        assert settings.assertion_consumer_service_url == Maestrano::SSO.consume_url
        assert settings.issuer == Maestrano.param('api.id')
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
      
      context "session management" do
        setup do
          @session = {}
          @auth = {
            extra: {
              session: {
                uid: 'usr-1',
                token: '15fg6d',
                recheck: Time.now,
                group_uid: 'cld-3'
              }
            }
          }
        end
      
        should "set the session correctly" do
          Maestrano::SSO.set_session(@session,@auth)
          decrypt_session = JSON.parse(Base64.decode64(@session[:maestrano]))
          assert_equal decrypt_session['uid'], @auth[:extra][:session][:uid]
          assert_equal decrypt_session['session'], @auth[:extra][:session][:token]
          assert_equal decrypt_session['session_recheck'], @auth[:extra][:session][:recheck].utc.iso8601
          assert_equal decrypt_session['group_uid'], @auth[:extra][:session][:group_uid]
        end
        
        should "unset the session correctly" do
          Maestrano::SSO.set_session(@session,@auth)
          Maestrano::SSO.clear_session(@session)
          assert @session[:maestrano].nil?
        end
        
        should "unset the session if key is a string" do
          @session['maestrano'] = "bla"
          Maestrano::SSO.clear_session(@session)
          assert @session["maestrano"].nil?
        end
        
        should "alias clear_session as unset_session" do
          Maestrano::SSO.set_session(@session,@auth)
          Maestrano::SSO.unset_session(@session)
          assert @session[:maestrano].nil?
        end
      end
    end

    context 'with preset' do
      setup do
        @preset = 'mypreset'

        @config = {
          'environment'       => 'production',
          'app.host'          => 'http://mysuperapp.com',
          
          'api.id'            => 'app-f54ds4f8',
          'api.key'           => 'someapikey',
          
          'sso.enabled'       => false,
          'sso.slo_enabled'   => false,
          'sso.init_path'     => '/mno/sso/init',
          'sso.consume_path'  => '/mno/sso/consume',
          'sso.creation_mode' => 'real',
          'sso.idm'           => 'http://idp.mysuperapp.com'
        }

        @preset_config = {
          'environment'       => 'production',
          'app.host'          => 'http://myotherapp.com',
          
          'api.id'            => 'app-553941',
          'api.key'           => 'otherapikey',

          'sso.enabled'       => false,
          'sso.slo_enabled'   => false,
          'sso.init_path'     => '/mno/sso/init',
          'sso.consume_path'  => '/mno/sso/consume',
          'sso.creation_mode' => 'real',
          'sso.idm'           => 'http://idp.myotherapp.com'
        }

        Maestrano.configure do |config|
          config.environment = @config['environment']
          config.app.host = @config['app.host']
          
          config.api.id = @config['api.id']
          config.api.key = @config['api.key']
          
          config.sso.enabled = @config['sso.enabled']
          config.sso.slo_enabled = @config['sso.slo_enabled']
          config.sso.idm = @config['sso.idm']
          config.sso.init_path = @config['sso.init_path']
          config.sso.consume_path = @config['sso.consume_path']
          config.sso.creation_mode = @config['sso.creation_mode']
        end
      
        Maestrano[@preset].configure do |config|
          config.environment = @preset_config['environment']
          config.app.host = @preset_config['app.host']
          
          config.api.id = @preset_config['api.id']
          config.api.key = @preset_config['api.key']
          
          config.sso.enabled = @preset_config['sso.enabled']
          config.sso.slo_enabled = @preset_config['sso.slo_enabled']
          config.sso.idm = @preset_config['sso.idm']
          config.sso.init_path = @preset_config['sso.init_path']
          config.sso.consume_path = @preset_config['sso.consume_path']
          config.sso.creation_mode = @preset_config['sso.creation_mode']
        end
      end
    
      should "return the right init_url" do
        assert_equal Maestrano::SSO[@preset].init_url, "http://idp.myotherapp.com/mno/sso/init"
      end
    
      should "return the right consume_url" do
        assert_equal Maestrano::SSO[@preset].consume_url, "http://idp.myotherapp.com/mno/sso/consume"
      end
    
      should "return the right logout_url" do
        assert_equal Maestrano::SSO[@preset].logout_url, "https://maestrano.com/app_logout"
      end
    
      should "return the right unauthorized_url" do
        assert_equal Maestrano::SSO[@preset].unauthorized_url, "https://maestrano.com/app_access_unauthorized"
      end
    
      should "return the right idp_url" do
        assert_equal Maestrano::SSO[@preset].idp_url, "https://maestrano.com/api/v1/auth/saml"
      end
    
      should "return the right session_check_url" do
        assert_equal Maestrano::SSO[@preset].session_check_url('usr-1','f9ds8fdg7f89'), "https://maestrano.com/api/v1/auth/saml/usr-1?session=f9ds8fdg7f89"
      end
    
      should "return the right enabled parameter" do
        assert_equal Maestrano::SSO[@preset].enabled?, !!Maestrano[@preset].param('sso.enabled')
      end
    
      should "return the right saml_settings" do
        settings = Maestrano::SSO[@preset].saml_settings
        assert settings.assertion_consumer_service_url == Maestrano::SSO[@preset].consume_url
        assert settings.issuer == Maestrano[@preset].param('api.id')
        assert settings.idp_sso_target_url == Maestrano::SSO[@preset].idp_url
        assert settings.idp_cert_fingerprint == Maestrano[@preset].param('sso_x509_fingerprint')
        assert settings.name_identifier_format == Maestrano[@preset].param('sso_name_id_format')
      end
    
      should "build the right saml request" do
        request = mock('request')
        Maestrano::Saml::Request.stubs(:new).with(group_id: "cld-3").returns(request)
        assert Maestrano::SSO[@preset].build_request(group_id: "cld-3") == request
      end
    
      should "build the right saml response" do
        response = mock('response')
        Maestrano::Saml::Response.stubs(:new).with(response_document).returns(response)
        response = Maestrano::SSO[@preset].build_response(response_document)
        assert Maestrano::SSO[@preset].build_response(response_document) == response
      end
      
      context "session management" do
        setup do
          @session = {}
          @auth = {
            extra: {
              session: {
                uid: 'usr-1',
                token: '15fg6d',
                recheck: Time.now,
                group_uid: 'cld-3'
              }
            }
          }
        end
      
        should "set the session correctly" do
          Maestrano::SSO[@preset].set_session(@session,@auth)
          decrypt_session = JSON.parse(Base64.decode64(@session[:maestrano]))
          assert_equal decrypt_session['uid'], @auth[:extra][:session][:uid]
          assert_equal decrypt_session['session'], @auth[:extra][:session][:token]
          assert_equal decrypt_session['session_recheck'], @auth[:extra][:session][:recheck].utc.iso8601
          assert_equal decrypt_session['group_uid'], @auth[:extra][:session][:group_uid]
        end
        
        should "unset the session correctly" do
          Maestrano::SSO[@preset].set_session(@session,@auth)
          Maestrano::SSO[@preset].clear_session(@session)
          assert @session[:maestrano].nil?
        end
        
        should "unset the session if key is a string" do
          @session['maestrano'] = "bla"
          Maestrano::SSO[@preset].clear_session(@session)
          assert @session["maestrano"].nil?
        end
        
        should "alias clear_session as unset_session" do
          Maestrano::SSO[@preset].set_session(@session,@auth)
          Maestrano::SSO[@preset].unset_session(@session)
          assert @session[:maestrano].nil?
        end
      end
    end
  end
end