require File.expand_path('../../test_helper', __FILE__)

class MaestranoTest < Test::Unit::TestCase
  setup do
    @config = {
      'environment'       => 'production',
      'app.host'          => 'http://mysuperapp.com',
      'api.id'            => 'app-f54ds4f8',
      'api.key'           => 'someapikey',
      'sso.enabled'       => false,
      'sso.init_path'     => '/mno/sso/init',
      'sso.consume_path'  => '/mno/sso/consume',
      'sso.creation_mode' => 'real',
      'sso.idm'           => 'http://idp.mysuperapp.com'
    }
  
    Maestrano.configure do |config|
      config.environment = @config['environment']
      config.app.host = @config['app.host']
      
      config.api.id = @config['api.id']
      config.api.key = @config['api.key']
      
      config.sso.enabled = @config['sso.enabled']
      config.sso.idm = @config['sso.idm']
      config.sso.init_path = @config['sso.init_path']
      config.sso.consume_path = @config['sso.consume_path']
      config.sso.creation_mode = @config['sso.creation_mode']
    end
  end
  
  context "new style configuration" do
    should "return the specified parameters" do
      @config.keys.each do |key|
        assert_equal @config[key], Maestrano.param(key)
      end
    end
    
    context "with environment params" do
      should "return the right test parameters" do
        Maestrano.configure { |config| config.environment = 'test' }
      
        ['api.host','api.base','sso.idp', 'sso.name_id_format', 'sso.x509_certificate'].each do |parameter|
          assert_equal Maestrano::Configuration::EVT_CONFIG['test'][parameter], Maestrano.param(parameter)
        end
      end
    
      should "return the right production parameters" do
        Maestrano.configure { |config| config.environment = 'production' }
      
        ['api.host','api.base','sso.idp', 'sso.name_id_format', 'sso.x509_certificate'].each do |parameter|
          assert_equal Maestrano::Configuration::EVT_CONFIG['production'][parameter], Maestrano.param(parameter)
        end
      end
    
      should "build the api_token based on the app_id and api_key" do
        Maestrano.configure { |config| config.app_id = "bla"; config.api_key = "blo" }
        assert_equal "bla:blo", Maestrano.param('api.token')
      end
    
      should "assign the sso.idm if explicitly set to nil" do
        Maestrano.configure { |config| config.sso.idm = nil }
        assert_equal Maestrano.param('app.host'), Maestrano.param('sso.idm')
      end
    end
  end
  
  
  context "old style configuration" do
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
    
    should "return the specified parameters" do
      @config.keys.each do |key|
        assert Maestrano.param(key) == @config[key]
      end
    end
    
    context "with environment params" do
      should "return the right test parameters" do
        Maestrano.configure { |config| config.environment = 'test' }
      
        ['api_host','api_base','sso_name_id_format', 'sso_x509_certificate'].each do |parameter|
          key = Maestrano::Configuration.new.legacy_param_to_new(parameter)
          assert_equal Maestrano::Configuration::EVT_CONFIG['test'][key], Maestrano.param(parameter)
        end
      end
    
      should "return the right production parameters" do
        Maestrano.configure { |config| config.environment = 'production' }
      
        ['api_host','api_base','sso_name_id_format', 'sso_x509_certificate'].each do |parameter|
          key = Maestrano::Configuration.new.legacy_param_to_new(parameter)
          assert_equal Maestrano::Configuration::EVT_CONFIG['production'][key], Maestrano.param(parameter)
        end
      end
    
      should "build the api_token based on the app_id and api_key" do
        Maestrano.configure { |config| config.app_id = "bla"; config.api_key = "blo" }
        assert_equal "bla:blo", Maestrano.param(:api_token)
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
end