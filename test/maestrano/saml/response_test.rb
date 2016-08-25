require File.expand_path('../../../test_helper', __FILE__)

module Maestrano
  module Saml
    class SamlTest < Test::Unit::TestCase
      include SamlTestHelper

      context "Response" do
        should "raise an exception when response is initialized with nil" do
          assert_raises(ArgumentError) { Maestrano::Saml::Response.new(nil) }
        end

        should "be able to parse a document which contains ampersands" do
          Maestrano::XMLSecurity::SignedDocument.any_instance.stubs(:digests_match?).returns(true)
          Maestrano::Saml::Response.any_instance.stubs(:validate_conditions).returns(true)

          response = Maestrano::Saml::Response.new(ampersands_response)
          settings = Maestrano::Saml::Settings.new
          settings.idp_cert_fingerprint = 'c51985d947f1be57082025050846eb27f6cab783'
          response.settings = settings
          response.validate!
        end

        should "adapt namespace" do
          response = Maestrano::Saml::Response.new(response_document)
          assert !response.name_id.nil?
          response = Maestrano::Saml::Response.new(response_document_2)
          assert !response.name_id.nil?
          response = Maestrano::Saml::Response.new(response_document_3)
          assert !response.name_id.nil?
        end

        should "default to raw input when a response is not Base64 encoded" do
          decoded  = Base64.decode64(response_document_2)
          response = Maestrano::Saml::Response.new(decoded)
          assert response.document
        end

        context "Assertion" do
          should "only retreive an assertion with an ID that matches the signature's reference URI" do
            response = Maestrano::Saml::Response.new(wrapped_response_2)
            response.stubs(:conditions).returns(nil)
            settings = Maestrano::Saml::Settings.new
            settings.idp_cert_fingerprint = signature_fingerprint_1
            response.settings = settings
            assert response.name_id.nil?
          end
        end

        context "#validate!" do
          should "raise when encountering a condition that prevents the document from being valid" do
            response = Maestrano::Saml::Response.new(response_document)
            assert_raise(Maestrano::Saml::ValidationError) do
              response.validate!
            end
          end
        end

        context "#is_valid?" do
          should "return false when response is initialized with blank data" do
            response = Maestrano::Saml::Response.new('')
            assert !response.is_valid?
          end

          should "return false if settings have not been set" do
            response = Maestrano::Saml::Response.new(response_document)
            assert !response.is_valid?
          end

          should "return true when the response is initialized with valid data" do
            response = Maestrano::Saml::Response.new(response_document_4)
            response.stubs(:conditions).returns(nil)
            assert !response.is_valid?
            settings = Maestrano::Saml::Settings.new
            assert !response.is_valid?
            response.settings = settings
            assert !response.is_valid?
            settings.idp_cert_fingerprint = signature_fingerprint_1
            assert response.is_valid?
          end

          should "should be idempotent when the response is initialized with invalid data" do
            response = Maestrano::Saml::Response.new(response_document_4)
            response.stubs(:conditions).returns(nil)
            settings = Maestrano::Saml::Settings.new
            response.settings = settings
            assert !response.is_valid?
            assert !response.is_valid?
          end

          should "should be idempotent when the response is initialized with valid data" do
            response = Maestrano::Saml::Response.new(response_document_4)
            response.stubs(:conditions).returns(nil)
            settings = Maestrano::Saml::Settings.new
            response.settings = settings
            settings.idp_cert_fingerprint = signature_fingerprint_1
            assert response.is_valid?
            assert response.is_valid?
          end

          should "return true when using certificate instead of fingerprint" do
            response = Maestrano::Saml::Response.new(response_document_4)
            response.stubs(:conditions).returns(nil)
            settings = Maestrano::Saml::Settings.new
            response.settings = settings
            settings.idp_cert = signature_1
            assert response.is_valid?
          end

          should "not allow signature wrapping attack" do
            response = Maestrano::Saml::Response.new(response_document_4)
            response.stubs(:conditions).returns(nil)
            settings = Maestrano::Saml::Settings.new
            settings.idp_cert_fingerprint = signature_fingerprint_1
            response.settings = settings
            assert response.is_valid?
            assert response.name_id == "test@onelogin.com"
          end

          should "support dynamic namespace resolution on signature elements" do
            response = Maestrano::Saml::Response.new(fixture("no_signature_ns.xml"))
            response.stubs(:conditions).returns(nil)
            settings = Maestrano::Saml::Settings.new
            response.settings = settings
            settings.idp_cert_fingerprint = "28:74:9B:E8:1F:E8:10:9C:A8:7C:A9:C3:E3:C5:01:6C:92:1C:B4:BA"
            Maestrano::XMLSecurity::SignedDocument.any_instance.expects(:validate_signature).returns(true)
            assert response.validate!
          end

          should "validate ADFS assertions" do
            response = Maestrano::Saml::Response.new(fixture(:adfs_response_sha256))
            response.stubs(:conditions).returns(nil)
            settings = Maestrano::Saml::Settings.new
            settings.idp_cert_fingerprint = "28:74:9B:E8:1F:E8:10:9C:A8:7C:A9:C3:E3:C5:01:6C:92:1C:B4:BA"
            response.settings = settings
            assert response.validate!
          end

          should "validate the digest" do
            response = Maestrano::Saml::Response.new(r1_response_document_6)
            response.stubs(:conditions).returns(nil)
            settings = Maestrano::Saml::Settings.new
            settings.idp_cert = Base64.decode64(r1_signature_2)
            response.settings = settings
            assert response.validate!
          end

          should "validate SAML 2.0 XML structure" do
            resp_xml = Base64.decode64(response_document_4).gsub(/emailAddress/,'test')
            response = Maestrano::Saml::Response.new(Base64.encode64(resp_xml))
            response.stubs(:conditions).returns(nil)
            settings = Maestrano::Saml::Settings.new
            settings.idp_cert_fingerprint = signature_fingerprint_1
            response.settings = settings
            assert_raises(Maestrano::Saml::ValidationError, 'Digest mismatch'){ response.validate! }
          end
        end

        context 'with presets' do
          context "#is_valid?" do
            setup do
              @preset = 'mypreset'

              @config = {
                'environment'       => 'production',
                'app.host'          => 'http://mysuperapp.com',

                'sso.enabled'       => false,
                'sso.slo_enabled'   => false,
                'sso.init_path'     => '/mno/sso/init',
                'sso.consume_path'  => '/mno/sso/consume',
                'sso.creation_mode' => 'real',
                'sso.idm'           => 'http://idp.mysuperapp.com'
              }

              @preset_config = {
                'environment'       => 'production',
                'app.host'          => 'http://myotherapp.com',

                'sso.enabled'       => false,
                'sso.slo_enabled'   => false,
                'sso.init_path'     => '/mno/sso/init',
                'sso.consume_path'  => '/mno/sso/consume',
                'sso.creation_mode' => 'real',
                'sso.idm'           => 'http://idp.myotherapp.com',
                'sso.x509_fingerprint' => signature_fingerprint_1,
                'sso.x509_certificate' => signature_1
              }

              Maestrano.configure do |config|
                config.environment = @config['environment']
                config.app.host = @config['app.host']

                config.sso.enabled = @config['sso.enabled']
                config.sso.slo_enabled = @config['sso.slo_enabled']
                config.sso.idm = @config['sso.idm']
                config.sso.init_path = @config['sso.init_path']
                config.sso.consume_path = @config['sso.consume_path']
                config.sso.creation_mode = @config['sso.creation_mode']
              end

              Maestrano[@preset].configure do |config|
                config.environment = @preset_config['environment']
                config.app.host = @preset_config['app.host']

                config.sso.enabled = @preset_config['sso.enabled']
                config.sso.slo_enabled = @preset_config['sso.slo_enabled']
                config.sso.idm = @preset_config['sso.idm']
                config.sso.init_path = @preset_config['sso.init_path']
                config.sso.consume_path = @preset_config['sso.consume_path']
                config.sso.creation_mode = @preset_config['sso.creation_mode']

                config.sso.x509_fingerprint = @preset_config['sso.x509_fingerprint']
                config.sso.x509_certificate = @preset_config['sso.x509_certificate']
              end
            end

            should "return true when using certificate instead of fingerprint" do
              response = Maestrano::Saml::Response[@preset].new(response_document_4)
              response.stubs(:conditions).returns(nil)
              assert response.is_valid?
            end

            should "not allow signature wrapping attack" do
              response = Maestrano::Saml::Response[@preset].new(response_document_4)
              response.stubs(:conditions).returns(nil)
              assert response.is_valid?
              assert response.name_id == "test@onelogin.com"
            end

            should "support dynamic namespace resolution on signature elements" do
              Maestrano[@preset].configure do |config|
                config.sso.x509_fingerprint = "28:74:9B:E8:1F:E8:10:9C:A8:7C:A9:C3:E3:C5:01:6C:92:1C:B4:BA"
                config.sso.x509_certificate = nil
              end

              response = Maestrano::Saml::Response[@preset].new(fixture("no_signature_ns.xml"))
              response.stubs(:conditions).returns(nil)
              Maestrano::XMLSecurity::SignedDocument.any_instance.expects(:validate_signature).returns(true)
              assert response.validate!
            end
          end
        end

        context "#name_id" do
          should "extract the value of the name id element" do
            response = Maestrano::Saml::Response.new(response_document)
            assert_equal "support@onelogin.com", response.name_id

            response = Maestrano::Saml::Response.new(response_document_3)
            assert_equal "someone@example.com", response.name_id
          end

          should "be extractable from an OpenSAML response" do
            response = Maestrano::Saml::Response.new(fixture(:open_saml))
            assert_equal "someone@example.org", response.name_id
          end

          should "be extractable from a Simple SAML PHP response" do
            response = Maestrano::Saml::Response.new(fixture(:simple_saml_php))
            assert_equal "someone@example.com", response.name_id
          end
        end

        context "#check_conditions" do
          should "check time conditions" do
            response = Maestrano::Saml::Response.new(response_document)
            assert !response.send(:validate_conditions, true)
            response = Maestrano::Saml::Response.new(response_document_6)
            assert response.send(:validate_conditions, true)
            time     = Time.parse("2011-06-14T18:25:01.516Z")
            Time.stubs(:now).returns(time)
            response = Maestrano::Saml::Response.new(response_document_5)
            assert response.send(:validate_conditions, true)
          end

          should "optionally allow for clock drift" do
            # The NotBefore condition in the document is 2011-06-14T18:21:01.516Z
            time  = Time.parse("2011-06-14T18:21:01Z")
            Time.stubs(:now).returns(time)
            response = Maestrano::Saml::Response.new(response_document_5, :allowed_clock_drift => 0.515)
            assert !response.send(:validate_conditions, true)

            response = Maestrano::Saml::Response.new(response_document_5, :allowed_clock_drift => 0.516)
            assert response.send(:validate_conditions, true)
          end
        end

        context "#attributes" do
          should "extract the first attribute in a hash accessed via its symbol" do
            response = Maestrano::Saml::Response.new(response_document)
            assert_equal "demo", response.attributes[:uid]
          end

          should "extract the first attribute in a hash accessed via its name" do
            response = Maestrano::Saml::Response.new(response_document)
            assert_equal "demo", response.attributes["uid"]
          end

          should "extract all attributes" do
            response = Maestrano::Saml::Response.new(response_document)
            assert_equal "demo", response.attributes[:uid]
            assert_equal "value", response.attributes[:another_value]
          end

          should "work for implicit namespaces" do
            response = Maestrano::Saml::Response.new(response_document_3)
            assert_equal "someone@example.com", response.attributes["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
          end

          should "not raise on responses without attributes" do
            response = Maestrano::Saml::Response.new(response_document_4)
            assert_equal Hash.new, response.attributes
          end

          context "#multiple values" do
            should "extract single value as string" do
              response = Maestrano::Saml::Response.new(fixture(:response_with_multiple_attribute_values))
              assert_equal "demo", response.attributes[:uid]
            end

            should "extract first of multiple values as string for b/w compatibility" do
              response = Maestrano::Saml::Response.new(fixture(:response_with_multiple_attribute_values))
              assert_equal 'value1', response.attributes[:another_value]
            end

            should "return array with all attributes when asked" do
              response = Maestrano::Saml::Response.new(fixture(:response_with_multiple_attribute_values))
              assert_equal ['value2', 'value1'], response.attributes[:another_value].values
            end

            should "return last of multiple values when multiple Attribute tags in XML" do
              response = Maestrano::Saml::Response.new(fixture(:response_with_multiple_attribute_values))
              assert_equal 'role2', response.attributes[:role]
            end

            should "return all of multiple values in reverse order when multiple Attribute tags in XML" do
              response = Maestrano::Saml::Response.new(fixture(:response_with_multiple_attribute_values))
              assert_equal ['role2', 'role1'], response.attributes[:role].values
            end
          end
        end

        context "#session_expires_at" do
          should "extract the value of the SessionNotOnOrAfter attribute" do
            response = Maestrano::Saml::Response.new(response_document)
            assert response.session_expires_at.is_a?(Time)

            response = Maestrano::Saml::Response.new(response_document_2)
            assert response.session_expires_at.nil?
          end
        end

        context "#issuer" do
          should "return the issuer inside the response assertion" do
            response = Maestrano::Saml::Response.new(response_document)
            assert_equal "https://app.onelogin.com/saml/metadata/13590", response.issuer
          end

          should "return the issuer inside the response" do
            response = Maestrano::Saml::Response.new(response_document_2)
            assert_equal "wibble", response.issuer
          end
        end

        context "#success" do
          should "find a status code that says success" do
            response = Maestrano::Saml::Response.new(response_document)
            response.success?
          end
        end

      end
    end
  end
end
