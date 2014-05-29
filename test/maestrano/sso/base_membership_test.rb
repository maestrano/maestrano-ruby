require File.expand_path('../../../test_helper', __FILE__)

module Maestrano
  module SSO
    class BaseMembershipTest < Test::Unit::TestCase
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
  
      should "extract the rights attributes from the saml response" do
        membership = Maestrano::SSO::BaseMembership.new(@saml_response)
        assert membership.group_uid == @saml_response.attributes['group_uid']
        assert membership.user_uid == @saml_response.attributes['uid']
        assert membership.role == @saml_response.attributes['group_role']
      end
  
      should "have the right hash representation" do
        membership = Maestrano::SSO::BaseMembership.new(@saml_response)
        assert membership.to_hash == {
          provider: 'maestrano',
          group_uid: membership.group_uid,
          user_uid: membership.user_uid,
          role: membership.role,
        }
      end
    end
  end
end