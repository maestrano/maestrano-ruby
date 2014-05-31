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
  
  should "return the specified parameters" do
    @config.keys.each do |key|
      assert Maestrano.param(key) == @config[key]
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