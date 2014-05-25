require 'maestrano'
require 'test/unit'
require 'shoulda'
require 'mocha/setup'
require 'timecop'

# Require all helpers
Dir[File.expand_path(File.join(File.dirname(__FILE__),"helpers/**/*.rb"))].each {|f| require f}

# Monkeypath request methods
module Maestrano
  module API
    module Operation
      module Base
        @mock_rest_client = nil

        def self.mock_rest_client=(mock_client)
          @mock_rest_client = mock_client
        end

        def self.execute_request(opts)
          get_params = (opts[:headers] || {})[:params]
          post_params = opts[:payload]
          case opts[:method]
          when :get then @mock_rest_client.get opts[:url], get_params, post_params
          when :post then @mock_rest_client.post opts[:url], get_params, post_params
          when :delete then @mock_rest_client.delete opts[:url], get_params, post_params
          end
        end
      end
    end
  end
end 

class Test::Unit::TestCase
  setup do
    @api_mock = mock('api_mock')
    Maestrano::API::Operation::Base.mock_rest_client = @api_mock
    Maestrano.configure do |config|
      config.api_key = "g15354F34f3x5z"
      config.environment = 'production'
    end
  end
end

