# -*- coding: utf-8 -*-
require File.expand_path('../../../test_helper', __FILE__)

module Maestrano
  module API
    class ResourceTest < Test::Unit::TestCase
      include APITestHelper
      
      should "creating a new Resource should not fetch over the network" do
        @api_mock.expects(:get).never
        Maestrano::Account::Bill.new("someid")
      end

      should "creating a new Resource from a hash should not fetch over the network" do
        @api_mock.expects(:get).never
        Maestrano::Account::Bill.construct_from({
          id: "somebill",
          object: "account_bill",
          price_cents: 2300,
          currency: 'AUD'
        })
      end

      should "setting an attribute should not cause a network request" do
        @api_mock.expects(:get).never
        @api_mock.expects(:post).never
        c = Maestrano::Account::Bill.new("test_account_bill");
        c.price_cents= 50000
      end

      should "accessing id should not issue a fetch" do
        @api_mock.expects(:get).never
        c = Maestrano::Account::Bill.new("test_account_bill");
        c.id
      end

      should "specifying invalid api credentials should raise an exception" do
        response = test_response(test_invalid_api_key_error, 401)
        assert_raises Maestrano::API::Error::AuthenticationError do
          @api_mock.expects(:get).once.raises(RestClient::ExceptionWithResponse.new(response, 401))
          Maestrano::Account::Bill.retrieve("failing_bill")
        end
      end

      should "AuthenticationErrors should have an http status, http body, and JSON body" do
        response = test_response(test_invalid_api_key_error, 401)
        begin
          @api_mock.expects(:get).once.raises(RestClient::ExceptionWithResponse.new(response, 401))
          Maestrano::Account::Bill.retrieve("failing_bill")
        rescue Maestrano::API::Error::AuthenticationError => e
          assert_equal(401, e.http_status)
          assert_equal(true, !!e.http_body)
          assert_equal(true, !!e.json_body[:errors])
          assert_equal(test_invalid_api_key_error['errors'].first.join(" "), e.json_body[:errors].first.join(" "))
        end
      end

      context "when specifying per-object credentials" do
        context "with no global API key set" do
          setup do
            @original_api_key = Maestrano.param('api_key')
            Maestrano.configure { |c| c.api_key = nil }
          end
          
          teardown do
            Maestrano.configure { |c| c.api_key = @original_api_key }
          end
          
          should "use the per-object credential when creating" do
            Maestrano::API::Operation::Base.expects(:execute_request).with do |opts|
              opts[:headers][:authorization] == "Basic #{Base64.encode64('sk_test_local:')}"
            end.returns(test_response(test_account_bill))

            Maestrano::Account::Bill.create({
                group_id: 'cld-1',
                price_cents: 23000,
                currency: 'AUD',
                description: 'Some bill'
              },
              'sk_test_local'
            )
          end
        end

        context "with a global API key set" do
          should "use the per-object credential when creating" do
            Maestrano::API::Operation::Base.expects(:execute_request).with do |opts|
              opts[:headers][:authorization] == "Basic #{Base64.encode64('local:')}"
            end.returns(test_response(test_account_bill))

            Maestrano::Account::Bill.create({
                group_id: 'cld-1',
                price_cents: 23000,
                currency: 'AUD',
                description: 'Some bill'
              },
              'local'
            )
          end

          should "use the per-object credential when retrieving and making other calls" do
            Maestrano::API::Operation::Base.expects(:execute_request).with do |opts|
              opts[:url] == "#{Maestrano.param('api_host')}#{Maestrano.param('api_base')}bills/ch_test_account_bill" &&
                opts[:headers][:authorization] == "Basic #{Base64.encode64('local:')}"
            end.returns(test_response(test_account_bill))
            Maestrano::API::Operation::Base.expects(:execute_request).with do |opts|
              opts[:url] == "#{Maestrano.param('api_host')}#{Maestrano.param('api_base')}bills/ch_test_account_bill" &&
                opts[:headers][:authorization] == "Basic #{Base64.encode64('local:')}" &&
                opts[:method] == :delete
            end.returns(test_response(test_account_bill))

            ch = Maestrano::Account::Bill.retrieve('ch_test_account_bill', 'local')
            ch.cancel
          end
        end
      end

      context "with valid credentials" do
        should "urlencode values in GET params" do
          response = test_response(test_account_bill_array)
          @api_mock.expects(:get).with("#{Maestrano.param('api_host')}#{Maestrano.param('api_base')}bills?bill=test%20bill", nil, nil).returns(response)
          bills = Maestrano::Account::Bill.all(:bill => 'test bill').data
          assert bills.kind_of? Array
        end

        should "construct URL properly with base query parameters" do
          response = test_response(test_account_bill_array)
          @api_mock.expects(:get).with("#{Maestrano.param('api_host')}#{Maestrano.param('api_base')}invoices?bill=test_account_bill", nil, nil).returns(response)
          invoices = Maestrano::Account::Bill.all(:bill => 'test_account_bill')

          @api_mock.expects(:get).with("#{Maestrano.param('api_host')}#{Maestrano.param('api_base')}invoices?bill=test_account_bill&paid=true", nil, nil).returns(response)
          invoices.all(:paid => true)
        end

        should "a 400 should give an InvalidRequestError with http status, body, and JSON body" do
          response = test_response(test_missing_id_error, 400)
          @api_mock.expects(:get).once.raises(RestClient::ExceptionWithResponse.new(response, 404))
          begin
            Maestrano::Account::Bill.retrieve("foo")
          rescue Maestrano::API::Error::InvalidRequestError => e
            assert_equal(400, e.http_status)
            assert_equal(true, !!e.http_body)
            assert_equal(true, e.json_body.kind_of?(Hash))
          end
        end

        should "a 401 should give an AuthenticationError with http status, body, and JSON body" do
          response = test_response(test_missing_id_error, 401)
          @api_mock.expects(:get).once.raises(RestClient::ExceptionWithResponse.new(response, 404))
          begin
            Maestrano::Account::Bill.retrieve("foo")
          rescue Maestrano::API::Error::AuthenticationError => e
            assert_equal(401, e.http_status)
            assert_equal(true, !!e.http_body)
            assert_equal(true, e.json_body.kind_of?(Hash))
          end
        end

        should "a 404 should give an InvalidRequestError with http status, body, and JSON body" do
          response = test_response(test_missing_id_error, 404)
          @api_mock.expects(:get).once.raises(RestClient::ExceptionWithResponse.new(response, 404))
          begin
            Maestrano::Account::Bill.retrieve("foo")
          rescue Maestrano::API::Error::InvalidRequestError => e
            assert_equal(404, e.http_status)
            assert_equal(true, !!e.http_body)
            assert_equal(true, e.json_body.kind_of?(Hash))
          end
        end

        should "setting a nil value for a param should exclude that param from the request" do
          @api_mock.expects(:get).with do |url, api_key, params|
            uri = URI(url)
            query = CGI.parse(uri.query)
            (url =~ %r{^#{Maestrano.param('api_host')}#{Maestrano.param('api_base')}bills?} &&
             query.keys.sort == ['offset', 'sad'])
          end.returns(test_response({ :count => 1, :data => [test_account_bill] }))
          Maestrano::Account::Bill.all(:count => nil, :offset => 5, :sad => false)

          @api_mock.expects(:post).with do |url, api_key, params|
            url == "#{Maestrano.param('api_host')}#{Maestrano.param('api_base')}bills" &&
              api_key.nil? &&
              CGI.parse(params) == { 'amount' => ['50'], 'currency' => ['usd'] }
          end.returns(test_response({ :count => 1, :data => [test_account_bill] }))
          Maestrano::Account::Bill.create({
            group_id: 'cld-1',
            price_cents: 23000,
            currency: 'AUD',
            description: 'Some bill'
          })
        end

        should "requesting with a unicode ID should result in a request" do
          response = test_response(test_missing_id_error, 404)
          @api_mock.expects(:get).once.with("#{Maestrano.param('api_host')}#{Maestrano.param('api_base')}bills/%E2%98%83", nil, nil).raises(RestClient::ExceptionWithResponse.new(response, 404))
          c = Maestrano::Account::Bill.new("☃")
          assert_raises(Maestrano::API::Error::InvalidRequestError) { c.refresh }
        end

        should "requesting with no ID should result in an InvalidRequestError with no request" do
          c = Maestrano::Account::Bill.new
          assert_raises(Maestrano::API::Error::InvalidRequestError) { c.refresh }
        end

        should "making a GET request with parameters should have a query string and no body" do
          params = { :limit => 1 }
          @api_mock.expects(:get).once.with("#{Maestrano.param('api_host')}#{Maestrano.param('api_base')}bills?limit=1", nil, nil).returns(test_response([test_account_bill]))
          Maestrano::Account::Bill.all(params)
        end

        should "making a POST request with parameters should have a body and no query string" do
          params = {
            group_id: 'cld-1',
            price_cents: 23000,
            currency: 'AUD',
            description: 'Some bill'
          },
          @api_mock.expects(:post).once.with do |url, get, post|
            get.nil? && CGI.parse(post) == {'group_id' => ['cld-1'], 'currency' => ['AUD'], 'price_cents' => ['23000'], 'description' => ['Some bill']}
          end.returns(test_response(test_account_bill))
          Maestrano::Account::Bill.create(params)
        end

        should "loading an object should issue a GET request" do
          @api_mock.expects(:get).once.returns(test_response(test_account_bill))
          c = Maestrano::Account::Bill.new("test_account_bill")
          c.refresh
        end

        should "using array accessors should be the same as the method interface" do
          @api_mock.expects(:get).once.returns(test_response(test_account_bill))
          c = Maestrano::Account::Bill.new("test_account_bill")
          c.refresh
          assert_equal c.created_at, c[:created_at]
          assert_equal c.created_at, c['created_at']
          date = Time.now.utc.iso8601
          c['created'] = date
          assert_equal c.created, date
        end

        should "accessing a property other than id or parent on an unfetched object should fetch it" do
          @api_mock.expects(:get).once.returns(test_response(test_account_bill))
          c = Maestrano::Account::Bill.new("test_account_bill")
          c.price_cents
        end

        should "updating an object should issue a POST request with only the changed properties" do
          @api_mock.expects(:post).with do |url, api_key, params|
            url == "#{Maestrano.param('api_host')}#{Maestrano.param('api_base')}bills/c_test_account_bill" && api_key.nil? && CGI.parse(params) == {'description' => ['another_mn']}
          end.once.returns(test_response(test_account_bill))
          c = Maestrano::Account::Bill.construct_from(test_account_bill)
          c.description = "another_mn"
          c.save
        end

        should "updating should merge in returned properties" do
          @api_mock.expects(:post).once.returns(test_response(test_account_bill))
          c = Maestrano::Account::Bill.new("c_test_account_bill")
          c.description = "another_mn"
          c.save
          assert_equal false, c.livemode
        end

        should "deleting should send no props and result in an object that has no props other deleted" do
          @api_mock.expects(:get).never
          @api_mock.expects(:post).never
          @api_mock.expects(:delete).with("#{Maestrano.param('api_host')}#{Maestrano.param('api_base')}bills/c_test_account_bill", nil, nil).once.returns(test_response({ "id" => "test_account_bill", "deleted" => true }))

          c = Maestrano::Account::Bill.construct_from(test_account_bill)
          class << c
            include Maestrano::API::Operation::Delete
          end
          
          c.delete
          assert_equal true, c.deleted

          assert_raises NoMethodError do
            c.livemode
          end
        end

        # should "loading an object with properties that have specific types should instantiate those classes" do
        #   @api_mock.expects(:get).once.returns(test_response(test_account_bill))
        #   c = Maestrano::Account::Bill.retrieve("test_account_bill")
        #   assert c.card.kind_of?(Maestrano::API::Object) && c.card.object == 'card'
        # end

        should "loading all of a Resource should return an array of recursively instantiated objects" do
          @api_mock.expects(:get).once.returns(test_response(test_account_bill_array))
          c = Maestrano::Account::Bill.all.data
          assert c.kind_of? Array
          assert c[0].kind_of? Maestrano::Account::Bill
          
          # No object to test for the moment
          #assert c[0].card.kind_of?(Maestrano::API::Object) && c[0].card.object == 'card'
        end

        context "error checking" do

          should "404s should raise an InvalidRequestError" do
            response = test_response(test_missing_id_error, 404)
            @api_mock.expects(:get).once.raises(RestClient::ExceptionWithResponse.new(response, 404))

            rescued = false
            begin
              Maestrano::Account::Bill.new("test_account_bill").refresh
              assert false #shouldn't get here either
            rescue Maestrano::API::Error::InvalidRequestError => e # we don't use assert_raises because we want to examine e
              rescued = true
              assert e.kind_of? Maestrano::API::Error::InvalidRequestError
              assert_equal "id", e.param
              assert_equal 'id does not exist', e.message
            end

            assert_equal true, rescued
          end

          should "5XXs should raise an API::Error" do
            response = test_response(test_api_error, 500)
            @api_mock.expects(:get).once.raises(RestClient::ExceptionWithResponse.new(response, 500))

            rescued = false
            begin
              Maestrano::Account::Bill.new("test_account_bill").refresh
              assert false #shouldn't get here either
            rescue Maestrano::API::Error::BaseError => e # we don't use assert_raises because we want to examine e
              rescued = true
              assert e.kind_of? Maestrano::API::Error::BaseError
            end

            assert_equal true, rescued
          end
          
        end
      end
    end
  end
end