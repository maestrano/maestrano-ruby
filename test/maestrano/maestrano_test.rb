require File.expand_path('../../test_helper', __FILE__)

class MaestranoTest < Test::Unit::TestCase
  setup do
    @config = {
      'environment'       => 'production',
      'app.host'          => 'http://mysuperapp.com',

      'api.id'            => 'app-f54ds4f8',
      'api.key'           => 'someapikey',

      'connec.enabled'    => true,

      'sso.enabled'       => false,
      'sso.slo_enabled'   => false,
      'sso.init_path'     => '/mno/sso/init',
      'sso.consume_path'  => '/mno/sso/consume',
      'sso.creation_mode' => 'real',
      'sso.idm'           => 'http://idp.mysuperapp.com',

      'webhook.account.groups_path'       => '/mno/groups/:id',
      'webhook.account.group_users_path'  => '/mno/groups/:group_id/users/:id',
      'webhook.connec.notifications_path' => 'mno/receive',
      'webhook.connec.subscriptions'      => { organizations: true, people: true }
    }

    Maestrano.configure do |config|
      config.environment = @config['environment']
      config.app.host = @config['app.host']

      config.api.id = @config['api.id']
      config.api.key = @config['api.key']

      config.connec.enabled = @config['connec.enabled']

      config.sso.enabled = @config['sso.enabled']
      config.sso.slo_enabled = @config['sso.slo_enabled']
      config.sso.idm = @config['sso.idm']
      config.sso.init_path = @config['sso.init_path']
      config.sso.consume_path = @config['sso.consume_path']
      config.sso.creation_mode = @config['sso.creation_mode']

      config.webhook.account.groups_path = @config['webhook.account.groups_path']
      config.webhook.account.group_users_path = @config['webhook.account.group_users_path']

      config.webhook.connec.notifications_path = @config['webhook.connec.notifications_path']
      config.webhook.connec.subscriptions = @config['webhook.connec.subscriptions']
    end
  end

  context "new style configuration" do
    should "return the specified parameters" do
      @config.keys.each do |key|
        assert_equal @config[key], Maestrano.param(key)
      end
    end

    should "set the sso.creation_mode to 'real' by default" do
      Maestrano.configs = {'default' => Maestrano::Configuration.new }
      Maestrano.configure { |config| config.app.host = "https://someapp.com" }
      assert_equal 'real', Maestrano.param('sso.creation_mode')
    end

    should "build the api_token based on the app_id and api_key" do
      Maestrano.configure { |config| config.app_id = "bla"; config.api_key = "blo" }
      assert_equal "bla:blo", Maestrano.param('api.token')
    end

    should "assign the sso.idm to app.host if not provided" do
      Maestrano.configs = {'default' => Maestrano::Configuration.new }
      Maestrano.configure { |config| config.app.host = "https://someapp.com" }
      assert_equal Maestrano.param('app.host'), Maestrano.param('sso.idm')
    end

    should "force assign the api.lang" do
      Maestrano.configure { |config| config.api.lang = "bla" }
      assert_equal 'ruby', Maestrano.param('api.lang')
    end

    should "force assign the api.lang_version" do
      Maestrano.configure { |config| config.api.lang_version = "123456" }
      assert_equal "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE})", Maestrano.param('api.lang_version')
    end

    should "force assign the api.version" do
      Maestrano.configure { |config| config.api.version = "1245" }
      assert_equal Maestrano::VERSION, Maestrano.param('api.version')
    end

    should "force slo_enabled to false if sso is disabled" do
      Maestrano.configure { |config| config.sso.slo_enabled = true; config.sso.enabled = false }
      assert_false Maestrano.param('sso.slo_enabled')
    end

    context "with environment params" do
      should "return the right test parameters" do
        Maestrano.reset!
        Maestrano.configure { |config| config.environment = 'test' }

        ['api.host', 'api.base', 'sso.idp', 'sso.name_id_format', 'sso.x509_certificate', 'connec.host', 'connec.base_path'].each do |parameter|
          assert_equal Maestrano::Configuration::EVT_CONFIG['test'][parameter], Maestrano.param(parameter)
        end
      end

      should "return the right production parameters" do
        Maestrano.configure { |config| config.environment = 'production' }

        ['api.host', 'api.base', 'sso.idp', 'sso.name_id_format', 'sso.x509_certificate', 'connec.host', 'connec.base_path'].each do |parameter|
          assert_equal Maestrano::Configuration::EVT_CONFIG['production'][parameter], Maestrano.param(parameter)
        end
      end
    end
  end

  context "new style configuration with presets" do
    setup do
      Maestrano.reset!

      @preset = 'mypreset'

      @config = {
        'environment'       => 'production',
        'app.host'          => 'http://mysuperapp.com',

        'api.id'            => 'app-f54ds4f8',
        'api.key'           => 'someapikey',

        'connec.enabled'    => true,

        'sso.enabled'       => false,
        'sso.slo_enabled'   => false,
        'sso.init_path'     => '/mno/sso/init',
        'sso.consume_path'  => '/mno/sso/consume',
        'sso.creation_mode' => 'real',
        'sso.idm'           => 'http://idp.mysuperapp.com',

        'webhook.account.groups_path'       => '/mno/groups/:id',
        'webhook.account.group_users_path'  => '/mno/groups/:group_id/users/:id',
        'webhook.connec.notifications_path' => 'mno/receive',
        'webhook.connec.subscriptions'      => { organizations: true, people: true }
      }

      @preset_config = {
        'environment'       => 'production',
        'app.host'          => 'http://myotherapp.com',

        'api.id'            => 'app-553941',
        'api.key'           => 'otherapikey',
      }

      Maestrano.configure do |config|
        config.environment = @config['environment']
        config.app.host = @config['app.host']

        config.api.id = @config['api.id']
        config.api.key = @config['api.key']

        config.connec.enabled = @config['connec.enabled']

        config.sso.enabled = @config['sso.enabled']
        config.sso.slo_enabled = @config['sso.slo_enabled']
        config.sso.idm = @config['sso.idm']
        config.sso.init_path = @config['sso.init_path']
        config.sso.consume_path = @config['sso.consume_path']
        config.sso.creation_mode = @config['sso.creation_mode']

        config.webhook.account.groups_path = @config['webhook.account.groups_path']
        config.webhook.account.group_users_path = @config['webhook.account.group_users_path']

        config.webhook.connec.notifications_path = @config['webhook.connec.notifications_path']
        config.webhook.connec.subscriptions = @config['webhook.connec.subscriptions']
      end

      Maestrano[@preset].configure do |config|
        config.environment = @preset_config['environment']
        config.app.host = @preset_config['app.host']

        config.api.id = @preset_config['api.id']
        config.api.key = @preset_config['api.key']
      end
    end

    should "return the specified parameters" do
      @preset_config.keys.each do |key|
        assert_equal @preset_config[key], Maestrano[@preset].param(key)
      end
    end

    should "set the sso.creation_mode to 'real' by default" do
      Maestrano.configs = {@preset => Maestrano::Configuration.new }
      Maestrano[@preset].configure { |config| config.app.host = "https://someapp.com" }
      assert_equal 'real', Maestrano[@preset].param('sso.creation_mode')
    end

    should "build the api_token based on the app_id and api_key" do
      Maestrano[@preset].configure { |config| config.app_id = "bla"; config.api_key = "blo" }
      assert_equal "bla:blo", Maestrano[@preset].param('api.token')
    end

    should "assign the sso.idm to app.host if not provided" do
      Maestrano.configs = {@preset => Maestrano::Configuration.new }
      Maestrano[@preset].configure { |config| config.app.host = "https://someapp.com" }
      assert_equal Maestrano[@preset].param('app.host'), Maestrano[@preset].param('sso.idm')
    end

    should "force assign the api.lang" do
      Maestrano[@preset].configure { |config| config.api.lang = "bla" }
      assert_equal 'ruby', Maestrano[@preset].param('api.lang')
    end

    should "force assign the api.lang_version" do
      Maestrano[@preset].configure { |config| config.api.lang_version = "123456" }
      assert_equal "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE})", Maestrano[@preset].param('api.lang_version')
    end

    should "force assign the api.version" do
      Maestrano[@preset].configure { |config| config.api.version = "1245" }
      assert_equal Maestrano::VERSION, Maestrano[@preset].param('api.version')
    end

    should "force slo_enabled to false if sso is disabled" do
      Maestrano[@preset].configure { |config| config.sso.slo_enabled = true; config.sso.enabled = false }
      assert_false Maestrano[@preset].param('sso.slo_enabled')
    end

    should "allow overwritting connec configuration" do
      Maestrano[@preset].configure { |config| config.connec.host = 'http://mydataserver.org'; config.connec.base_path = '/data' }
      assert_equal 'http://mydataserver.org', Maestrano[@preset].param('connec.host')
      assert_equal '/data', Maestrano[@preset].param('connec.base_path')
    end

    context "with environment params" do
      should "return the right test parameters" do
        @preset = 'test'
        Maestrano[@preset].configure { |config| config.environment = 'test' }

        ['api.host','api.base','sso.idp', 'sso.name_id_format', 'sso.x509_certificate', 'connec.host','connec.base_path'].each do |parameter|
          assert_equal Maestrano::Configuration::EVT_CONFIG['test'][parameter], Maestrano[@preset].param(parameter)
        end
      end

      should "return the right production parameters" do
        Maestrano[@preset].configure { |config| config.environment = 'production' }

        ['api.host','api.base','sso.idp', 'sso.name_id_format', 'sso.x509_certificate','connec.host','connec.base_path'].each do |parameter|
          assert_equal Maestrano::Configuration::EVT_CONFIG['production'][parameter], Maestrano[@preset].param(parameter)
        end
      end
    end

    context 'with dynamic dev platform config' do
      context 'with no config' do
        should 'raise error' do
          assert_raise { Maestrano.auto_configure }
        end
      end

      context 'with an invalid config' do
        should 'raise error' do
          assert_raise { Maestrano.auto_configure('test/support/yml/wrong_dev_platform.yml') }
        end
      end

      context 'with a valid config' do
        context 'with no response from dev plateform' do
          should 'raise error' do
            assert_raise { Maestrano.auto_configure('test/support/yml/dev_platform.yml') }
          end
        end

        context 'with bad response from dev plateform' do
          setup do
            RestClient::Request.any_instance.stubs(:execute).returns('<html></html>')
          end

          should 'raise error' do
            assert_raise { Maestrano.auto_configure('test/support/yml/dev_platform.yml') }
          end
        end

        context 'with valid response from dev plateform' do
          setup do
            @preset = 'this_awesome_one'
            @marketplace = {
              marketplace: @preset,
              environment: "myotherapp-uat",
              app: {
                host: 'http://myotherapp.uat.com'
              },
              api: {
                id: "app-abcd",
                key: "642be9cd60eb17f50deaf416787274a9e07f4b8b2e99103e578bc61859410c5f",
                host: "https://api-hub-uat.maestrano.io",
                base: "/api/v1/"
              },
              sso: {
                idm: "http://rails-demoapp.maestrano.io",
                init_path: "/maestrano/auth/saml/init/#{@preset}",
                consume_path: "/maestrano/auth/saml/consume/#{@preset}",
                idp: "https://api-hub-uat.maestrano.io",
                x509_fingerprint: "29:C2:88:D9:F5:C5:30:D3:D4:D5:0B:9F:0D:D6:2E:3A:0F:80:7C:50",
                x509_certificate: "-----BEGIN CERTIFICATE-----\nMIIDeTCCAmGgAwIBAgIBAzANBgkqhkiG9w0BAQsFADBMMQswCQYDVQQGEwJBVTEa\nMBgGA1UECgwRTWFlc3RyYW5vIFB0eSBMdGQxITAfBgNVBAMMGGRldmVsb3BlcnMu\nbWFlc3RyYW5vLmNvbTAeFw0xNjA4MjUwNTQwNTFaFw0zNjA4MjYwNTQwNTFaMEQx\nCzAJBgNVBAYTAkFVMRowGAYDVQQKDBFNYWVzdHJhbm8gUHR5IEx0ZDEZMBcGA1UE\nAwwQdWF0Lm1hZXN0cmFuby5pbzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC\nggEBAK4aVXl1EpXOXA11rcay+g/lmkm0r5zSWT5b8TpIqpD/qbvaF/qwp1kKKhBw\nzMz5896GAjmPQCYfGeKy1aSleh17FUPKAtYr/qL5DpVOpDBmA3kI8BXUeVveiY3Y\nhoylqyucE+Ch+iBJ/Rx3hPxHvQlRWl/SugmHX/RbX3UsHBepBc9VA5yfT9CNwwPK\nZ63opQ6fZJlRJ1uPnhkJpA/e/72F3kPZClreVe2TRKuCij+TFb+3gOKB08qJdhjK\nVnOgJcb9XWcdpsV35KvvvwffSHxjqt4SSwVdy5mhvkJcjwVRaE1xHUq7CXRxJ/X2\nowG5SQbUjTj6Hu4q4NdvbKxRYU0CAwEAAaNuMGwwLQYJYIZIAYb4QgENBCAWHk1h\nZXN0cmFubyBJbnRlcm5hbCBDZXJ0aWZpY2F0ZTAdBgNVHQ4EFgQUPk2GG6uGEnDc\nqgqbEtWuak8sjwQwDAYDVR0TAQH/BAIwADAOBgNVHQ8BAf8EBAMCBLAwDQYJKoZI\nhvcNAQELBQADggEBAJMTiBbxwV0irz7R8Zpxo2mCVm0JcUoyL//NsRkgOSbN1q75\nsfBKDLCGuG79/JpBbmKKFVlZplWyLjKPhkE6Mz3/lJ5U0dKQOI7rfqtZYjEyxpr5\nHaju5Uxm7VMyIrVDgJFeFZQu76CCe7sw6qKfZoHMbrcNuQQzBrCc1pOikHqCtRE5\nTeNfkpUiBvXWb8GVYwa9G95BOUa3feK/8gmhcrv4XMtJkJbn3hCobkZcws2kQT6k\nOEmKL7ZFXtZjc/RNYEiUzeBJbLRTg+tJEZcLW3MdyLYlYgZqwaLp/Q4pmqbQqC/n\nX9wrxgOYwrA+JT7Dc0kfhis5sWVBokFnbPTOxQw=\n-----END CERTIFICATE-----\n"
              },
              connec: {
                host: "http://api-connec.uat.maestrano.io"
              }
            }
            @marketplaces = {
              marketplaces: [@marketplace]
            }

            RestClient::Request.any_instance.stubs(:execute).returns(@marketplaces.to_json)
          end

          should 'creates a new preset' do
            @preset = 'this_awesome_one'
            assert_nothing_raised { Maestrano.auto_configure('test/support/yml/dev_platform.yml') }

            assert_equal @preset, Maestrano.configs[@preset].param('environment')
            assert_equal @marketplace[:app][:host], Maestrano.configs[@preset].param('app.host')
            assert_equal @marketplace[:api][:id], Maestrano.configs[@preset].param('api.id')
            assert_equal @marketplace[:api][:key], Maestrano.configs[@preset].param('api.key')
            assert_equal @marketplace[:api][:host], Maestrano.configs[@preset].param('api.host')
            assert_equal @marketplace[:api][:base], Maestrano.configs[@preset].param('api.base')
            assert_equal @marketplace[:sso][:idm], Maestrano.configs[@preset].param('sso.idm')
            assert_equal @marketplace[:sso][:init_path], Maestrano.configs[@preset].param('sso.init_path')
            assert_equal @marketplace[:sso][:consume_path], Maestrano.configs[@preset].param('sso.consume_path')
            assert_equal @marketplace[:sso][:idp], Maestrano.configs[@preset].param('sso.idp')
            assert_equal @marketplace[:sso][:x509_fingerprint], Maestrano.configs[@preset].param('sso.x509_fingerprint')
            assert_equal @marketplace[:sso][:x509_certificate], Maestrano.configs[@preset].param('sso.x509_certificate')
            assert_equal @marketplace[:connec][:host], Maestrano.configs[@preset].param('connec.host')
          end

          should 'overwrites the exisiting preset' do
            assert_nothing_raised { Maestrano.auto_configure('test/support/yml/dev_platform.yml') }

            assert_equal @preset, Maestrano.configs[@preset].param('environment')
            assert_equal @marketplace[:app][:host], Maestrano.configs[@preset].param('app.host')
            assert_equal @marketplace[:api][:id], Maestrano.configs[@preset].param('api.id')
            assert_equal @marketplace[:api][:key], Maestrano.configs[@preset].param('api.key')
            assert_equal @marketplace[:api][:host], Maestrano.configs[@preset].param('api.host')
            assert_equal @marketplace[:api][:base], Maestrano.configs[@preset].param('api.base')
            assert_equal @marketplace[:sso][:idm], Maestrano.configs[@preset].param('sso.idm')
            assert_equal @marketplace[:sso][:init_path], Maestrano.configs[@preset].param('sso.init_path')
            assert_equal @marketplace[:sso][:consume_path], Maestrano.configs[@preset].param('sso.consume_path')
            assert_equal @marketplace[:sso][:idp], Maestrano.configs[@preset].param('sso.idp')
            assert_equal @marketplace[:sso][:x509_fingerprint], Maestrano.configs[@preset].param('sso.x509_fingerprint')
            assert_equal @marketplace[:sso][:x509_certificate], Maestrano.configs[@preset].param('sso.x509_certificate')
            assert_equal @marketplace[:connec][:host], Maestrano.configs[@preset].param('connec.host')
          end
        end

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

    should "build the api_token based on the app_id and api_key" do
      Maestrano.configure { |config| config.app_id = "bla"; config.api_key = "blo" }
      assert_equal "bla:blo", Maestrano.param(:api_token)
    end

    should "assign the sso.idm if explicitly set to nil" do
      Maestrano.configure { |config| config.sso.idm = nil }
      assert_equal Maestrano.param('app.host'), Maestrano.param('sso.idm')
    end

    should "force assign the api.lang" do
      Maestrano.configure { |config| config.api.lang = "bla" }
      assert_equal 'ruby', Maestrano.param('api.lang')
    end

    should "force assign the api.lang_version" do
      Maestrano.configure { |config| config.api.lang_version = "123456" }
      assert_equal "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE})", Maestrano.param('api.lang_version')
    end

    should "force assign the api.version" do
      Maestrano.configure { |config| config.api.version = "1245" }
      assert_equal Maestrano::VERSION, Maestrano.param('api.version')
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
