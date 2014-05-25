require File.expand_path('../../../test_helper', __FILE__)

class BaseUserTest < Test::Unit::TestCase
  include SamlTestHelper
  
  setup do
    @saml_response = Maestrano::Saml::Response.new(response_document)
    @saml_response.stubs(:attributes).returns({
      'mno_session'          => 'f54sd54fd64fs5df4s3d48gf2',
      'mno_session_recheck'  => Time.now.utc.iso8601,
      'group_uid'            => 'cld-1',
      'group_end_free_trial' => Time.now.utc.iso8601,
      'group_role'           => 'Admin',
      'uid'                  => "usr-1",
      'virtual_uid'          => "usr-1.cld-1",
      'email'                => "j.doe@doecorp.com",
      'virtual_email'        => "usr-1.cld-1@mail.maestrano.com",
      'name'                 => "John",
      "surname"              => "Doe",
      "country"              => "AU",
      "company_name"         => "DoeCorp"
    })
  end
  
  should "have a local_id accessor" do
    assert Maestrano::SSO::BaseUser.new(@saml_response).respond_to?(:local_id) == true
  end
  
  should "extract the rights attributes from the saml response" do
    user = Maestrano::SSO::BaseUser.new(@saml_response)
    assert user.sso_session == @saml_response.attributes['mno_session']
    assert user.sso_session_recheck == Time.iso8601(@saml_response.attributes['mno_session_recheck'])
    assert user.group_uid == @saml_response.attributes['group_uid']
    assert user.group_role == @saml_response.attributes['group_role']
    assert user.uid == @saml_response.attributes['uid']
    assert user.virtual_uid == @saml_response.attributes['virtual_uid']
    assert user.email == @saml_response.attributes['email']
    assert user.virtual_email == @saml_response.attributes['virtual_email']
    assert user.first_name == @saml_response.attributes['name']
    assert user.last_name == @saml_response.attributes['surname']
    assert user.country == @saml_response.attributes['country']
    assert user.company_name == @saml_response.attributes['company_name']
  end
  
  context "to_hash presentation" do
    should "have the right representation when user_creation_mode is virtual" do
      Maestrano.configure { |config| config.user_creation_mode = 'virtual' }
      sso_user = Maestrano::SSO::BaseUser.new(@saml_response)
      assert sso_user.to_hash == {
        provider: 'maestrano',
        uid: sso_user.virtual_uid,
        info: {
          email: sso_user.virtual_email,
          first_name: sso_user.first_name,
          last_name: sso_user.last_name,
          country: sso_user.country,
          company_name: sso_user.company_name,
        },
        extra: {
          uid: sso_user.uid,
          virtual_uid: sso_user.virtual_uid,
          real_email: sso_user.email,
          virtual_email: sso_user.virtual_email,
          group: {
            uid: sso_user.group_uid,
            role: sso_user.group_role
          }
        }
      }
    end
    
    should "have the right representation when user_creation_mode is real" do
      Maestrano.configure { |config| config.user_creation_mode = 'real' }
      sso_user = Maestrano::SSO::BaseUser.new(@saml_response)
      assert sso_user.to_hash == {
        provider: 'maestrano',
        uid: sso_user.uid,
        info: {
          email: sso_user.email,
          first_name: sso_user.first_name,
          last_name: sso_user.last_name,
          country: sso_user.country,
          company_name: sso_user.company_name,
        },
        extra: {
          uid: sso_user.uid,
          virtual_uid: sso_user.virtual_uid,
          real_email: sso_user.email,
          virtual_email: sso_user.virtual_email,
          group: {
            uid: sso_user.group_uid,
            role: sso_user.group_role,
          }
        }
      }
    end
  end
end