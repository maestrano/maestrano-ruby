# libs
require 'rest_client'
require 'json'

# Version
require 'maestrano/version'

# XMLSecurity
require 'maestrano/xml_security/signed_document'

# SAML
require 'maestrano/saml/request'
require 'maestrano/saml/attribute_value'
require 'maestrano/saml/response'
require 'maestrano/saml/settings'
require 'maestrano/saml/validation_error'
require 'maestrano/saml/metadata'

# SSO
require 'maestrano/sso'
require 'maestrano/sso/base_user'
require 'maestrano/sso/base_group'
require 'maestrano/sso/session'
require 'maestrano/sso/user'
require 'maestrano/sso/group'

# API Errors
require 'maestrano/api/error/base_error'
require 'maestrano/api/error/authentication_error'
require 'maestrano/api/error/connection_error'
require 'maestrano/api/error/invalid_request_error'

# API Operations
require 'maestrano/api/operation/base'
require 'maestrano/api/operation/create'
require 'maestrano/api/operation/delete'
require 'maestrano/api/operation/list'
require 'maestrano/api/operation/update'

# API
require 'maestrano/api/util'
require 'maestrano/api/object'
require 'maestrano/api/list_object'
require 'maestrano/api/resource'

# API - Account Entities
require 'maestrano/account/bill'

module Maestrano
  
  class << self
    attr_accessor :config
  end
  
  # Maestrano Configuration block
  def self.configure
    self.config ||= Configuration.new
    yield(config)
  end
  
  # Get configuration parameter value
  # E.g:
  # Maestrano.param('api_key')
  # Maestrano.param(:api_key)
  def self.param(parameter)
    self.config.param(parameter)
  end

  class Configuration
    attr_accessor :environment, :api_key, :sso_enabled, 
      :app_host, :sso_app_init_path, :sso_app_consume_path, :user_creation_mode,
      :verify_ssl_certs, :api_version

    def initialize
      @environment = 'test'
      @api_key = nil
      @sso_enabled = true
      @app_host = 'http://localhost:3000'
      @sso_app_init_path = '/maestrano/auth/saml/init'
      @sso_app_consume_path = '/maestrano/auth/saml/consume'
      @user_creation_mode = 'virtual'
      @verify_ssl_certs = false
      @api_version = nil
    end
    
    # Get configuration parameter value
    def param(parameter)
      if self.respond_to?(parameter)
        self.send(parameter)
      elsif EVT_CONFIG[@environment.to_sym].has_key?(parameter.to_sym)
        EVT_CONFIG[@environment.to_sym][parameter.to_sym]
      else
        raise ArgumentError, "No such configuration parameter: '#{parameter}'"
      end
    end
    
    EVT_CONFIG = {
      test: {
        api_host: 'http://api-sandbox.maestrano.io',
        api_base: '/api/v1/',
        sso_name_id_format: Maestrano::Saml::Settings::NAMEID_PERSISTENT,
        sso_x509_fingerprint: '01:06:15:89:25:7d:78:12:28:a6:69:c7:de:63:ed:74:21:f9:f5:36',
        sso_x509_certificate: "-----BEGIN CERTIFICATE-----\nMIIDezCCAuSgAwIBAgIJAOehBr+YIrhjMA0GCSqGSIb3DQEBBQUAMIGGMQswCQYD\nVQQGEwJBVTEMMAoGA1UECBMDTlNXMQ8wDQYDVQQHEwZTeWRuZXkxGjAYBgNVBAoT\nEU1hZXN0cmFubyBQdHkgTHRkMRYwFAYDVQQDEw1tYWVzdHJhbm8uY29tMSQwIgYJ\nKoZIhvcNAQkBFhVzdXBwb3J0QG1hZXN0cmFuby5jb20wHhcNMTQwMTA0MDUyMjM5\nWhcNMzMxMjMwMDUyMjM5WjCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEP\nMA0GA1UEBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQG\nA1UEAxMNbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVz\ndHJhbm8uY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDVkIqo5t5Paflu\nP2zbSbzxn29n6HxKnTcsubycLBEs0jkTkdG7seF1LPqnXl8jFM9NGPiBFkiaR15I\n5w482IW6mC7s8T2CbZEL3qqQEAzztEPnxQg0twswyIZWNyuHYzf9fw0AnohBhGu2\n28EZWaezzT2F333FOVGSsTn1+u6tFwIDAQABo4HuMIHrMB0GA1UdDgQWBBSvrNxo\neHDm9nhKnkdpe0lZjYD1GzCBuwYDVR0jBIGzMIGwgBSvrNxoeHDm9nhKnkdpe0lZ\njYD1G6GBjKSBiTCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEPMA0GA1UE\nBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQGA1UEAxMN\nbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVzdHJhbm8u\nY29tggkA56EGv5giuGMwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQUFAAOBgQCc\nMPgV0CpumKRMulOeZwdpnyLQI/NTr3VVHhDDxxCzcB0zlZ2xyDACGnIG2cQJJxfc\n2GcsFnb0BMw48K6TEhAaV92Q7bt1/TYRvprvhxUNMX2N8PHaYELFG2nWfQ4vqxES\nRkjkjqy+H7vir/MOF3rlFjiv5twAbDKYHXDT7v1YCg==\n-----END CERTIFICATE-----"
      },
      production: {
        api_host: 'https://maestrano.com',
        api_base: '/api/v1/',
        sso_name_id_format: Maestrano::Saml::Settings::NAMEID_PERSISTENT,
        sso_x509_fingerprint: '2f:57:71:e4:40:19:57:37:a6:2c:f0:c5:82:52:2f:2e:41:b7:9d:7e',
        sso_x509_certificate: "-----BEGIN CERTIFICATE-----\nMIIDezCCAuSgAwIBAgIJAPFpcH2rW0pyMA0GCSqGSIb3DQEBBQUAMIGGMQswCQYD\nVQQGEwJBVTEMMAoGA1UECBMDTlNXMQ8wDQYDVQQHEwZTeWRuZXkxGjAYBgNVBAoT\nEU1hZXN0cmFubyBQdHkgTHRkMRYwFAYDVQQDEw1tYWVzdHJhbm8uY29tMSQwIgYJ\nKoZIhvcNAQkBFhVzdXBwb3J0QG1hZXN0cmFuby5jb20wHhcNMTQwMTA0MDUyNDEw\nWhcNMzMxMjMwMDUyNDEwWjCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEP\nMA0GA1UEBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQG\nA1UEAxMNbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVz\ndHJhbm8uY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQD3feNNn2xfEz5/\nQvkBIu2keh9NNhobpre8U4r1qC7h7OeInTldmxGL4cLHw4ZAqKbJVrlFWqNevM5V\nZBkDe4mjuVkK6rYK1ZK7eVk59BicRksVKRmdhXbANk/C5sESUsQv1wLZyrF5Iq8m\na9Oy4oYrIsEF2uHzCouTKM5n+O4DkwIDAQABo4HuMIHrMB0GA1UdDgQWBBSd/X0L\n/Pq+ZkHvItMtLnxMCAMdhjCBuwYDVR0jBIGzMIGwgBSd/X0L/Pq+ZkHvItMtLnxM\nCAMdhqGBjKSBiTCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEPMA0GA1UE\nBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQGA1UEAxMN\nbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVzdHJhbm8u\nY29tggkA8WlwfatbSnIwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQUFAAOBgQDE\nhe/18oRh8EqIhOl0bPk6BG49AkjhZZezrRJkCFp4dZxaBjwZTddwo8O5KHwkFGdy\nyLiPV326dtvXoKa9RFJvoJiSTQLEn5mO1NzWYnBMLtrDWojOe6Ltvn3x0HVo/iHh\nJShjAn6ZYX43Tjl1YXDd1H9O+7/VgEWAQQ32v8p5lA==\n-----END CERTIFICATE-----"
      }
    }
  end
end