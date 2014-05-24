require File.expand_path('../../test_helper', __FILE__)

class SSOTest < Test::Unit::TestCase
  setup do
    Maestrano.configure { |config| config.environment = 'production' }
  end
  
  should "return the right init_url" do
    assert Maestrano::SSO.init_url == "http://localhost:3000/maestrano/auth/saml/init"
  end
  
  should "return the right consume_url" do
    assert Maestrano::SSO.consume_url == "http://localhost:3000/maestrano/auth/saml/consume"
  end
  
  should "return the right logout_url" do
    assert Maestrano::SSO.logout_url == "https://maestrano.com/app_logout"
  end
  
  should "return the right unauthorized_url" do
    assert Maestrano::SSO.unauthorized_url == "https://maestrano.com/app_access_unauthorized"
  end
  
  should "return the right idp_url" do
    assert Maestrano::SSO.idp_url == "https://maestrano.com/api/v1/auth/saml"
  end
  
  should "return the right session_check_url" do
    assert Maestrano::SSO.session_check_url('usr-1','f9ds8fdg7f89') == "https://maestrano.com/api/v1/auth/saml/usr-1?session=f9ds8fdg7f89"
  end
end