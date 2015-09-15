require File.expand_path('../../../test_helper', __FILE__)

module Maestrano
  module Account
    class UserTest < Test::Unit::TestCase
      include APITestHelper
      
      should "should be listable" do
        @api_mock.expects(:get).once.returns(test_response(test_account_user_array))
        c = Maestrano::Account::User.all
        assert c.data.kind_of? Array
        c.each do |entity|
          assert entity.kind_of?(Maestrano::Account::User)
        end
      end

      should "should not be updateable" do
        assert_raises NoMethodError do
          @api_mock.stubs(:put).returns(test_response(test_account_user))
          c = Maestrano::Account::User.construct_from(test_account_user[:data])
          c.save
        end
      end
      
      should "should not be creatable" do
        assert_raises NoMethodError do
          @api_mock.stubs(:post).returns(test_response(test_account_user))
          c = Maestrano::Account::User.create({name: "Bla"})
        end
      end

      context 'with presets' do
        setup do
          @preset = 'mypreset'
          Maestrano[@preset].configure do |config|
            config.environment = 'production'
            config.api.host = 'https://myprovider.com'
            config.api.base = '/myapi'
          end
        end

        should "should successfully list remote users" do
          @api_mock.expects(:get).with do |url, api_token|
            url == "#{Maestrano[@preset].param('api.host')}#{Maestrano[@preset].param('api.base')}account/users" && api_token.nil?
          end.once.returns(test_response(test_account_user_array))

          bills = Maestrano::Account::User[@preset].all
          assert bills
        end
      end
    end
  end
end