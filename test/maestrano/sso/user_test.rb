require File.expand_path('../../../test_helper', __FILE__)

module Maestrano
  module SSO
    class UserTest < Test::Unit::TestCase
      setup do
        @user = mock('user')
        class << @user
          include Maestrano::SSO::User
        end
      end

      context "find_for_maestrano_auth" do
        should "raise an error if not overriden" do
          assert_raise(NoMethodError.new("You need to override find_for_maestrano_auth in your Mocha::Mock model")) do
            @user.find_for_maestrano_auth({})
          end
        end

        should "execute properly otherwise" do
          def @user.find_for_maestrano_auth(auth); return true; end
          assert_nothing_thrown do
            @user.find_for_maestrano_auth({})
          end
        end
      end

      context "maestrano?" do
        should "raise an error if no provider attribute and not overriden" do
          assert_raise(NoMethodError.new("You need to override maestrano? in your Mocha::Mock model")) do
            @user.maestrano?
          end
        end

        should "return true if the provider is 'maestrano'" do
          @user.stubs(:provider).returns('maestrano')
          assert @user.maestrano?
        end

        should "return false if the provider is something else" do
          @user.stubs(:provider).returns('someprovider')
          assert !@user.maestrano?
        end
      end

      context "maestrano_session_valid?" do
        should "return true if the sso session is valid" do
          session = {}
          sso_session = mock('sso_session')
          Maestrano::SSO::Session.stubs(:new).with(session).returns(sso_session)
          sso_session.stubs(:valid?).returns(true)
          assert @user.maestrano_session_valid?(session)
        end

        should "return false if the sso session is invalid" do
          session = {}
          sso_session = mock('sso_session')
          Maestrano::SSO::Session.stubs(:new).with(session).returns(sso_session)
          sso_session.stubs(:valid?).returns(false)
          assert !@user.maestrano_session_valid?(session)
        end
      end
    end
  end
end
