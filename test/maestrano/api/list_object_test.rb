require File.expand_path('../../../test_helper', __FILE__)

module Maestrano
  module API
    class ListObjectTest < Test::Unit::TestCase
      include APITestHelper
      
      should "be able to retrieve full lists given a listobject" do
        @api_mock.expects(:get).twice.returns(test_response(test_account_bill_array))
        c = Maestrano::Account::Bill.all
        assert c.kind_of?(Maestrano::API::ListObject)
        assert_equal('bills', c.url)
        all = c.all
        assert all.kind_of?(Maestrano::API::ListObject)
        assert_equal('bills', all.url)
        assert all.data.kind_of?(Array)
      end
    end
  end
end