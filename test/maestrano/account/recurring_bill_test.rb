require File.expand_path('../../../test_helper', __FILE__)

module Maestrano
  module Account
    class RecurringBillTest < Test::Unit::TestCase
      include APITestHelper
      
      should "be listable" do
        @api_mock.expects(:get).once.returns(test_response(test_account_recurring_bill_array))
        c = Maestrano::Account::RecurringBill.all
        assert c.data.kind_of? Array
        c.each do |bill|
          assert bill.kind_of?(Maestrano::Account::RecurringBill)
        end
      end

      should "be cancellable" do
        @api_mock.expects(:delete).once.returns(test_response(test_account_recurring_bill))
        c = Maestrano::Account::RecurringBill.construct_from(test_account_recurring_bill[:data])
        c.cancel
      end

      should "not be updateable" do
        assert_raises NoMethodError do
          @api_mock.stubs(:put).returns(test_response(test_account_recurring_bill))
          c = Maestrano::Account::RecurringBill.construct_from(test_account_recurring_bill[:data])
          c.save
        end
      end


      should "successfully create a remote bill when passed correct parameters" do
        @api_mock.expects(:post).with do |url, api_key, params|
          url == "#{Maestrano.param('api_host')}#{Maestrano.param('api_base')}account/recurring_bills" && api_key.nil? && 
          CGI.parse(params) == {"group_id"=>["cld-1"], "price_cents"=>["23000"], "currency"=>["AUD"], "description"=>["Some recurring bill"], "period"=>["Month"]}
        end.once.returns(test_response(test_account_recurring_bill))

        recurring_bill = Maestrano::Account::RecurringBill.create({
          group_id: 'cld-1',
          price_cents: 23000,
          currency: 'AUD',
          description: 'Some recurring bill',
          period: 'Month'
        })
        assert recurring_bill.id
      end
    end
  end
end