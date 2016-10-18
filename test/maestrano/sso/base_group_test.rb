require File.expand_path('../../../test_helper', __FILE__)

module Maestrano
  module SSO
    class BaseGroupTest < Test::Unit::TestCase
      include SamlTestHelper

      setup do
        @saml_response = Maestrano::Saml::Response.new(response_document)
        @saml_response.stubs(:attributes).returns({
          'mno_session'          => 'f54sd54fd64fs5df4s3d48gf2',
          'mno_session_recheck'  => Time.now.utc.iso8601,
          'group_uid'            => 'cld-1',
          'group_name'           => 'Some Group Name',
          'group_org_uid'        => 'org-48',
          'group_currency'       => 'AUD',
          'group_timezone'       => 'America/Los_Angeles',
          'group_email'          => 'principal@maestrano.com',
          'group_end_free_trial' => Time.now.utc.iso8601,
          'group_role'           => 'Admin',
          'group_country'        => 'AU',
          'group_city'           => 'Sydney',
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
        assert Maestrano::SSO::BaseGroup.new(@saml_response).respond_to?(:local_id) == true
      end

      should "extract the rights attributes from the saml response" do
        group = Maestrano::SSO::BaseGroup.new(@saml_response)
        assert group.uid == @saml_response.attributes['group_uid']
        assert group.has_credit_card == (@saml_response.attributes['group_has_credit_card'] == 'true')
        assert group.free_trial_end_at == Time.iso8601(@saml_response.attributes['group_end_free_trial'])
        assert group.company_name == @saml_response.attributes['company_name']
        assert group.name == @saml_response.attributes['group_name']
        assert group.org_uid == @saml_response.attributes['group_org_uid']
        assert group.email == @saml_response.attributes['group_email']
        assert group.currency == @saml_response.attributes['group_currency']
        assert group.timezone == @saml_response.attributes['group_timezone']
        assert group.city == @saml_response.attributes['group_city']
        assert group.email == @saml_response.attributes['group_email']
        assert group.country == @saml_response.attributes['country']
      end

      should "have the right hash representation" do
        sso_group = Maestrano::SSO::BaseGroup.new(@saml_response)
        assert sso_group.to_hash == {
          provider: 'maestrano',
          uid: sso_group.uid,
          info: {
            free_trial_end_at: sso_group.free_trial_end_at,
            company_name: sso_group.company_name,
            has_credit_card: sso_group.has_credit_card,
            name: sso_group.name,
            org_uid: sso_group.org_uid,
            email: sso_group.email,
            city: sso_group.city,
            country: sso_group.country,
            timezone: sso_group.timezone,
            currency: sso_group.currency
          },
          extra: {}
        }
      end
    end
  end
end
