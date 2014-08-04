module APITestHelper
  def test_response(body={}, code=200)
    # When an exception is raised, restclient clobbers method_missing.  Hence we
    # can't just use the stubs interface.
    body = JSON.generate(body) if !(body.kind_of? String)
    m = mock
    m.instance_variable_set('@resp_values', { :body => body, :code => code })
    def m.body; @resp_values[:body]; end
    def m.code; @resp_values[:code]; end
    m
  end
  
  def test_account_group_content(params={})
    {
      object: 'account_group',
      id: 'cld-4f5d',
      created_at: Time.now.utc.iso8601,
      updated_at: Time.now.utc.iso8601,
      has_credit_card: true,
      status: 'running',
    }.merge(params)
  end
  
  def test_account_group(params={})
    {
      success: true,
      errors: {},
      data: test_account_group_content(params)
    }
  end
  
  def test_account_group_array
    {
      success: true,
      errors: {},
      data: [test_account_group_content, test_account_group_content, test_account_group_content],
    }
  end
  
  def test_account_user_content(params={})
    {
      object: 'account_user',
      id: 'usr-123',
      name: 'John',
      surname: 'Doe',
      email: 'john.doe@maestrano.com',
      company_name: 'DoeCorp',
      country: 'AU',
      sso_session: 'd45sg47f52sd1cz7x5c44czx7czx7',
      created_at: Time.now.utc.iso8601,
      updated_at: Time.now.utc.iso8601,
    }.merge(params)
  end
  
  def test_account_user(params={})
    {
      success: true,
      errors: {},
      data: test_account_user_content(params)
    }
  end
  
  def test_account_user_array
    {
      success: true,
      errors: {},
      data: [test_account_user_content, test_account_user_content, test_account_user_content],
    }
  end
  
  def test_account_bill_content(params={})
    {
      object: 'account_bill',
      id: 'bill-1',
      group_id: 'cld-1',
      created_at: Time.now.utc.iso8601,
      price_cents: 2300,
      status: 'submitted',
      currency: 'AUD',
      units: 1,
      description: 'Bill for something',
      period_start: Time.now.utc.iso8601,
      period_end: (Time.now + 3600000).utc.iso8601,
    }.merge(params)
  end
  
  def test_account_bill(params={})
    {
      success: true,
      errors: {},
      data: test_account_bill_content(params)
    }
  end
  
  def test_account_bill_array
    {
      success: true,
      errors: {},
      data: [test_account_bill_content, test_account_bill_content, test_account_bill_content],
    }
  end
  
  def test_account_bill_array_one
    {
      success: true,
      errors: {},
      data: [test_account_bill_content],
    }
  end
  
  def test_account_recurring_bill_content(params={})
    {
      object: 'account_recurring_bill',
      id: 'rbill-1',
      group_id: 'cld-1',
      created_at: Time.now.utc.iso8601,
      price_cents: 2300,
      status: 'submitted',
      currency: 'AUD',
      description: 'Bill for something',
      start_date: Time.now.utc.iso8601,
      period: 'Month',
      frequency: 1,
      cycles: nil
    }.merge(params)
  end
  
  def test_account_recurring_bill(params={})
    {
      success: true,
      errors: {},
      data: test_account_recurring_bill_content(params)
    }
  end
  
  def test_account_recurring_bill_array
    {
      success: true,
      errors: {},
      data: [test_account_recurring_bill_content, test_account_recurring_bill_content, test_account_recurring_bill_content],
    }
  end
  
  def test_invalid_api_token_error
    {
      'success' => false,
      'data' => {},
      "errors" => {
        "authentication" => ["Invalid API token"],
      }
    }
  end
  
  def test_missing_id_error
    {
      'success' => false,
      'data' => {},
      'errors' => {
        'id' => ["does not exist"]
      }
    }
  end
  
  def test_api_error
    {
      'success' => false,
      'data' => {},
      'errors' => {
        'system' => ["A system error occured. Please retry later or contact support@maestrano.com if the issue persists."]
      }
    }
  end
end