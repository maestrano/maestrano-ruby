require File.expand_path('../../../test_helper', __FILE__)

module Maestrano
  module Account
    class GroupTest < Test::Unit::TestCase
      include APITestHelper
      
      should "should be listable" do
        @api_mock.expects(:get).once.returns(test_response(test_account_group_array))
        c = Maestrano::Account::Group.all
        assert c.data.kind_of? Array
        c.each do |entity|
          assert entity.kind_of?(Maestrano::Account::Group)
        end
      end

      should "should not be updateable" do
        assert_raises NoMethodError do
          @api_mock.stubs(:put).returns(test_response(test_account_group))
          c = Maestrano::Account::Group.construct_from(test_account_group[:data])
          c.save
        end
      end
      
      should "should not be creatable" do
        assert_raises NoMethodError do
          @api_mock.stubs(:post).returns(test_response(test_account_group))
          c = Maestrano::Account::Group.create({name: "Bla"})
        end
      end
    end
  end
end