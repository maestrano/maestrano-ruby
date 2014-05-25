require File.expand_path('../../../test_helper', __FILE__)

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
  
end