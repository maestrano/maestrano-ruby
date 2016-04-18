require File.expand_path('../../../test_helper', __FILE__)

module Maestrano
  module Connec
    class ClientTest < Test::Unit::TestCase
      
      context 'without preset' do
        context 'initializer' do
          context '.base_uri' do
            context 'in test' do
              setup { Maestrano.configs = {}; Maestrano.configure { |config| config.environment = 'test' } }
              setup { @client = Maestrano::Connec::Client.new("cld-123") }
              
              should "return the right uri" do
                assert_equal "http://api-sandbox.maestrano.io/connec/api/v2", Maestrano::Connec::Client.base_uri
              end
            end
          
            context 'in production' do
              setup { Maestrano.configs = {}; Maestrano.configure { |config| config.environment = 'production' } }
              setup { @client = Maestrano::Connec::Client.new("cld-123") }
              
              should "return the right uri" do
                assert_equal "https://api-connec.maestrano.com/api/v2", Maestrano::Connec::Client.base_uri
              end
            end
          end
        end
        
        context 'scoped_path' do
          setup { @client = Maestrano::Connec::Client.new("cld-123") }
          
          should "return the right scoped path" do
            assert_equal "/cld-123/people", @client.scoped_path('/people')
          end
          
          should "remove any leading or trailing slash" do
            assert_equal "/cld-123/people", @client.scoped_path('/people/')
          end
        end
        
        context 'default_options' do
          setup { @client = Maestrano::Connec::Client.new("cld-123") }
          
          should "return the right authentication options" do
            expected_opts = {
              basic_auth: { 
                username: Maestrano.param('api.id'), 
                password: Maestrano.param('api.key')
              },
              timeout: Maestrano.param('connec.timeout')
            }
            assert_equal expected_opts, @client.default_options
          end
        end
        
        context 'get' do
          setup { @client = Maestrano::Connec::Client.new("cld-123") }
          
          should "perform the right query" do
            path = '/people'
            opts = { foo: 'bar' }
            resp = mock('resp')
            Maestrano::Connec::Client.expects(:get).with(@client.scoped_path(path),@client.default_options.merge(opts)).returns(resp)
            assert_equal resp, @client.get(path,opts)
          end
        end
        
        context 'post' do
          setup { @client = Maestrano::Connec::Client.new("cld-123") }
          
          should "perform the right query" do
            path = '/people'
            body = { some: 'data'}
            opts = { foo: 'bar' }
            resp = mock('resp')
            Maestrano::Connec::Client.expects(:post).with(@client.scoped_path(path),@client.default_options.merge(body: body.to_json).merge(opts)).returns(resp)
            assert_equal resp, @client.post(path,body,opts)
          end
        end
        
        context 'put' do
          setup { @client = Maestrano::Connec::Client.new("cld-123") }
          
          should "perform the right query" do
            path = '/people/123'
            body = { some: 'data'}
            opts = { foo: 'bar' }
            resp = mock('resp')
            Maestrano::Connec::Client.expects(:put).with(@client.scoped_path(path),@client.default_options.merge(body: body.to_json).merge(opts)).returns(resp)
            assert_equal resp, @client.put(path,body,opts)
          end
        end

        context 'batch' do
          setup { @client = Maestrano::Connec::Client.new("cld-123") }
          
          should "perform the right query" do
            body = { some: 'data'}
            opts = { foo: 'bar' }
            resp = mock('resp')
            Maestrano::Connec::Client.expects(:post).with("#{Maestrano.param('connec.host')}/batch",@client.default_options.merge(body: body.to_json).merge(opts)).returns(resp)
            assert_equal resp, @client.batch(body,opts)
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

            'connec.enabled'    => true,
            'connec.host'       => 'https://connec-api.com',
            'connec.base_path'  => '/api'
          }

          @preset_config = {
            'environment'       => 'production',
            'app.host'          => 'http://myotherapp.com',
            
            'api.id'            => 'app-553941',
            'api.key'           => 'otherapikey',

            'connec.enabled'    => true,
            'connec.host'       => 'https://other-provider.com',
            'connec.base_path'  => '/data'
          }

          Maestrano.configure do |config|
            config.environment = @config['environment']
            config.app.host = @config['app.host']
            
            config.api.id = @config['api.id']
            config.api.key = @config['api.key']

            config.connec.enabled = @config['connec.enabled']
            config.connec.host = @config['connec.host']
            config.connec.base_path = @config['connec.base_path']
          end
        
          Maestrano[@preset].configure do |config|
            config.environment = @preset_config['environment']
            config.app.host = @preset_config['app.host']
            
            config.api.id = @preset_config['api.id']
            config.api.key = @preset_config['api.key']

            config.connec.enabled = @preset_config['connec.enabled']
            config.connec.host = @preset_config['connec.host']
            config.connec.base_path = @preset_config['connec.base_path']
          end
        end

        context 'initializer' do
          context '.base_uri' do
            context 'in test' do
              setup { Maestrano[@preset].configure { |config| config.environment = 'test' } }
              setup { @client = Maestrano::Connec::Client[@preset].new("cld-123") }
              
              should "return the right uri" do
                assert_equal "https://other-provider.com/data", Maestrano::Connec::Client[@preset].base_uri
              end
            end
          
            context 'in production' do
              setup { Maestrano[@preset].configure { |config| config.environment = 'production' } }
              setup { @client = Maestrano::Connec::Client[@preset].new("cld-123") }
              
              should "return the right uri" do
                assert_equal "https://other-provider.com/data", Maestrano::Connec::Client[@preset].base_uri
              end
            end
          end
        end
        
        context 'scoped_path' do
          setup { @client = Maestrano::Connec::Client[@preset].new("cld-123") }
          
          should "return the right scoped path" do
            assert_equal "/cld-123/people", @client.scoped_path('/people')
          end
          
          should "remove any leading or trailing slash" do
            assert_equal "/cld-123/people", @client.scoped_path('/people/')
          end
        end
        
        context 'default_options' do
          setup { @client = Maestrano::Connec::Client[@preset].new("cld-123") }
          
          should "return the right authentication options" do
            expected_opts = {
              basic_auth: { 
                username: Maestrano[@preset].param('api.id'), 
                password: Maestrano[@preset].param('api.key')
              },
              timeout: Maestrano[@preset].param('connec.timeout')
            }
            assert_equal expected_opts, @client.default_options
          end
        end
        
        context 'get' do
          setup { @client = Maestrano::Connec::Client[@preset].new("cld-123") }
          
          should "perform the right query" do
            path = '/people'
            opts = { foo: 'bar' }
            resp = mock('resp')
            Maestrano::Connec::Client[@preset].expects(:get).with(@client.scoped_path(path),@client.default_options.merge(opts)).returns(resp)
            assert_equal resp, @client.get(path,opts)
          end
        end
        
        context 'post' do
          setup { @client = Maestrano::Connec::Client[@preset].new("cld-123") }
          
          should "perform the right query" do
            path = '/people'
            body = { some: 'data'}
            opts = { foo: 'bar' }
            resp = mock('resp')
            Maestrano::Connec::Client[@preset].expects(:post).with(@client.scoped_path(path),@client.default_options.merge(body: body.to_json).merge(opts)).returns(resp)
            assert_equal resp, @client.post(path,body,opts)
          end
        end
        
        context 'put' do
          setup { @client = Maestrano::Connec::Client[@preset].new("cld-123") }
          
          should "perform the right query" do
            path = '/people/123'
            body = { some: 'data'}
            opts = { foo: 'bar' }
            resp = mock('resp')
            Maestrano::Connec::Client[@preset].expects(:put).with(@client.scoped_path(path),@client.default_options.merge(body: body.to_json).merge(opts)).returns(resp)
            assert_equal resp, @client.put(path,body,opts)
          end
        end
      end
    end
  end
end