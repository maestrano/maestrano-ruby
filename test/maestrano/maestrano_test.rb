require File.expand_path('../../test_helper', __FILE__)

class MaestranoTest < Test::Unit::TestCase
  setup do
    @config = {
      environment: 'production',
      api_key: 'someapikey',
      sso_enabled: false,
      app_host: 'http://mysuperapp.com',
      sso_app_init_path: '/mno/sso/init',
      sso_app_consume_path: '/mno/sso/consume',
      user_creation_mode: 'real',
    }
    
    Maestrano.configure do |config|
      config.environment = @config[:environment]
      config.api_key = @config[:api_key]
      config.sso_enabled = @config[:sso_enabled]
      config.app_host = @config[:app_host]
      config.sso_app_init_path = @config[:sso_app_init_path]
      config.sso_app_consume_path = @config[:sso_app_consume_path]
      config.user_creation_mode = @config[:user_creation_mode]
    end
  end
  
  context "param" do
    should "return the specified parameters" do
      @config.keys.each do |key|
        assert Maestrano.param(key) == @config[key]
      end
    end
  end
  
  context "authenticate" do
    should "return true if app_id and api_key match" do
      assert Maestrano.authenticate(Maestrano.param(:app_id),Maestrano.param(:api_key))
    end
    
    should "return false otherwise" do
      assert !Maestrano.authenticate(Maestrano.param(:app_id) + 'a',Maestrano.param(:api_key))
      assert !Maestrano.authenticate(Maestrano.param(:app_id),Maestrano.param(:api_key) + 'a')
    end
  end
  
  context "mask_user_uid" do
    should "return the composite uid if creation_mode is virtual" do
      Maestrano.configure { |c| c.user_creation_mode = 'virtual' }
      assert_equal 'usr-1.cld-1', Maestrano.mask_user('usr-1','cld-1')
    end
    
    should "not double up the composite uid" do
      Maestrano.configure { |c| c.user_creation_mode = 'virtual' }
      assert_equal 'usr-1.cld-1', Maestrano.mask_user('usr-1.cld-1','cld-1')
    end
    
    should "return the real uid if creation_mode is real" do
      Maestrano.configure { |c| c.user_creation_mode = 'real' }
      assert_equal 'usr-1', Maestrano.mask_user('usr-1','cld-1')
    end
  end
  
  context "unmask_user_uid" do
    should "return the right uid if composite" do
      assert_equal 'usr-1', Maestrano.unmask_user('usr-1.cld-1')
    end
    
    should "return the right uid if non composite" do
      assert_equal 'usr-1', Maestrano.unmask_user('usr-1')
    end
  end
  
  
  context "configuration" do
    should "return the right test parameters" do
      Maestrano.configure { |config| config.environment = 'test' }
      
      ['api_host','api_base','sso_name_id_format', 'sso_x509_certificate'].each do |parameter|
        assert Maestrano.param(parameter) == Maestrano::Configuration::EVT_CONFIG[:test][parameter.to_sym]
      end
    end
    
    should "return the right production parameters" do
      Maestrano.configure { |config| config.environment = 'production' }
      
      ['api_host','api_base','sso_name_id_format', 'sso_x509_certificate'].each do |parameter|
        assert Maestrano.param(parameter) == Maestrano::Configuration::EVT_CONFIG[:production][parameter.to_sym]
      end
    end
    
    should "build the api_token based on the app_id and api_key" do
      Maestrano.configure { |config| config.app_id = "bla"; config.api_key = "blo" }
      assert_equal "bla:blo", Maestrano.param(:api_token)
    end
  end
end