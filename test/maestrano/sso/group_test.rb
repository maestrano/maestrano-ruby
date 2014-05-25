require File.expand_path('../../../test_helper', __FILE__)

module Maestrano
  module SSO
    class GroupTest < Test::Unit::TestCase
      setup do
        @group = mock('group')
        class << @group
          include Maestrano::SSO::Group
        end
      end
  
      context "find_for_maestrano_auth" do
        should "raise an error if not overriden" do
          assert_raise(NoMethodError.new("You need to override find_for_maestrano_auth in your Mocha::Mock model")) do
            @group.find_for_maestrano_auth({})
          end
        end
    
        should "execute properly otherwise" do
          def @group.find_for_maestrano_auth(auth); return true; end
          assert_nothing_thrown do
            @group.find_for_maestrano_auth({})
          end
        end
      end
  
      context "maestrano?" do
        should "raise an error if no provider attribute and not overriden" do
          assert_raise(NoMethodError.new("You need to override maestrano? in your Mocha::Mock model")) do
            @group.maestrano?
          end
        end
    
        should "return true if the provider is 'maestrano'" do
          @group.stubs(:provider).returns('maestrano')
          assert @group.maestrano?
        end
    
        should "return false if the provider is something else" do
          @group.stubs(:provider).returns('someprovider')
          assert !@group.maestrano?
        end
      end
    end
  end
end