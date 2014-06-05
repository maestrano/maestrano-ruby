# libs
require 'rest_client'
require 'json'
require 'ostruct'

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
require 'maestrano/sso/base_membership'
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
require 'maestrano/account/recurring_bill'

module Maestrano
  
  class << self
    attr_accessor :config
  end
  
  # Maestrano Configuration block
  def self.configure
    self.config ||= Configuration.new
    yield(config)
    self.config.api.token = "#{self.config.api.id}:#{self.config.api.key}"
    self.config.sso.idm ||= self.config.app.host
  end
  
  # Check that app_id and api_key passed
  # in argument match
  def self.authenticate(app_id,api_key)
    self.param(:app_id) == app_id && self.param(:api_key) == api_key
  end
  
  # Take a user uid (either real or virtual)
  # and a group id and return the user uid that should
  # be used within the app based on the user_creation_mode
  # parameter:
  # 'real': then the real user uid is returned (usr-4d5sfd)
  # 'virtual': then the virtual user uid is returned (usr-4d5sfd.cld-g4f5d)
  def self.mask_user(user_uid,group_uid)
    sanitized_user_uid = self.unmask_user(user_uid)
    if Maestrano.param('user_creation_mode') == 'virtual'
      return "#{sanitized_user_uid}.#{group_uid}"
    else
      return sanitized_user_uid
    end
  end
  
  # Take a user uid (either real or virtual)
  # and return the real uid part
  def self.unmask_user(user_uid)
    user_uid.split(".").first
  end
  
  # Get configuration parameter value
  # E.g:
  # Maestrano.param('api_key')
  # Maestrano.param(:api_key)
  def self.param(parameter)
    self.config.param(parameter)
  end
  
  # Return a hash describing the current
  # Maestrano configuration. The metadata
  # will be remotely fetched by Maestrano
  def to_metadata
    
  end

  class Configuration
    attr_accessor :environment, :app, :sso, :api

    def initialize
      @environment = 'test'
      
      # App config
      @app = OpenStruct.new({
        host: 'http://localhost:3000'
      })
      
      # API Config
      @api = OpenStruct.new({
        id: nil,
        key: nil,
        token: nil,
        version: nil,
        verify_ssl_certs: false,
      })
      
      # SSO Config
      @sso = OpenStruct.new({
        enabled: true,
        creation_mode: 'virtual',
        init_path: '/maestrano/auth/saml/init',
        consume_path: '/maestrano/auth/saml/consume',
        idm: @app.host
      })
    end
    
    # Transform legacy parameters into new parameter
    # style
    # Dummy mapping
    def legacy_param_to_new(parameter)
      case parameter.to_s
      when 'user_creation_mode'
        return 'sso.creation_mode'
      when 'verify_ssl_certs'
        return 'api.verify_ssl_certs'
      when 'app_id'
        return 'api.id'
      when /^app_(.*)/i
        return "app.#{$1}"
      when /^api_(.*)/i
        return "api.#{$1}"
      when /^sso_app_(.*)/i
        return "sso.#{$1}"
      when /^sso_(.*)/i
        return "sso.#{$1}"
      else
        return parameter.to_s
      end
    end
    
    # Handle legacy parameter assignment
    def method_missing(meth, *args, &block)
      if meth.to_s =~ /^((?:sso|app|api|user)_.*)=$/
        new_meth = self.legacy_param_to_new($1) + '='
        group, prop = new_meth.split('.')
        self.send(group).send(prop, *args, &block)
      else
        super
      end
    end
    
    # Get configuration parameter value
    def param(parameter)
      real_param = self.legacy_param_to_new(parameter)
      group, param = real_param.split('.')
      
      if self.respond_to?(real_param) || (self.respond_to?(group) && self.send(group).respond_to?(param))
        param ? self.send(group).send(param) : self.send(real_param)
      elsif EVT_CONFIG[@environment.to_s].has_key?(real_param.to_s)
        EVT_CONFIG[@environment.to_s][real_param.to_s]
      else
        raise ArgumentError, "No such configuration parameter: '#{parameter}'"
      end
    end
    
    EVT_CONFIG = {
      'test' => {
        'api.host'             => 'http://api-sandbox.maestrano.io',
        'api.base'             => '/api/v1/',
        'sso.idp'              => 'https://maestrano.com',
        'sso.name_id_format'   => Maestrano::Saml::Settings::NAMEID_PERSISTENT,
        'sso.x509_fingerprint' => '01:06:15:89:25:7d:78:12:28:a6:69:c7:de:63:ed:74:21:f9:f5:36',
        'sso.x509_certificate' => "-----BEGIN CERTIFICATE-----\nMIIDezCCAuSgAwIBAgIJAOehBr+YIrhjMA0GCSqGSIb3DQEBBQUAMIGGMQswCQYD\nVQQGEwJBVTEMMAoGA1UECBMDTlNXMQ8wDQYDVQQHEwZTeWRuZXkxGjAYBgNVBAoT\nEU1hZXN0cmFubyBQdHkgTHRkMRYwFAYDVQQDEw1tYWVzdHJhbm8uY29tMSQwIgYJ\nKoZIhvcNAQkBFhVzdXBwb3J0QG1hZXN0cmFuby5jb20wHhcNMTQwMTA0MDUyMjM5\nWhcNMzMxMjMwMDUyMjM5WjCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEP\nMA0GA1UEBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQG\nA1UEAxMNbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVz\ndHJhbm8uY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDVkIqo5t5Paflu\nP2zbSbzxn29n6HxKnTcsubycLBEs0jkTkdG7seF1LPqnXl8jFM9NGPiBFkiaR15I\n5w482IW6mC7s8T2CbZEL3qqQEAzztEPnxQg0twswyIZWNyuHYzf9fw0AnohBhGu2\n28EZWaezzT2F333FOVGSsTn1+u6tFwIDAQABo4HuMIHrMB0GA1UdDgQWBBSvrNxo\neHDm9nhKnkdpe0lZjYD1GzCBuwYDVR0jBIGzMIGwgBSvrNxoeHDm9nhKnkdpe0lZ\njYD1G6GBjKSBiTCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEPMA0GA1UE\nBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQGA1UEAxMN\nbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVzdHJhbm8u\nY29tggkA56EGv5giuGMwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQUFAAOBgQCc\nMPgV0CpumKRMulOeZwdpnyLQI/NTr3VVHhDDxxCzcB0zlZ2xyDACGnIG2cQJJxfc\n2GcsFnb0BMw48K6TEhAaV92Q7bt1/TYRvprvhxUNMX2N8PHaYELFG2nWfQ4vqxES\nRkjkjqy+H7vir/MOF3rlFjiv5twAbDKYHXDT7v1YCg==\n-----END CERTIFICATE-----"
      },
      'production' => {
        'api.host'             => 'https://maestrano.com',
        'api.base'             => '/api/v1/',
        'sso.idp'              => 'https://maestrano.com',
        'sso.name_id_format'   => Maestrano::Saml::Settings::NAMEID_PERSISTENT,
        'sso.x509_fingerprint' => '2f:57:71:e4:40:19:57:37:a6:2c:f0:c5:82:52:2f:2e:41:b7:9d:7e',
        'sso.x509_certificate' => "-----BEGIN CERTIFICATE-----\nMIIDezCCAuSgAwIBAgIJAPFpcH2rW0pyMA0GCSqGSIb3DQEBBQUAMIGGMQswCQYD\nVQQGEwJBVTEMMAoGA1UECBMDTlNXMQ8wDQYDVQQHEwZTeWRuZXkxGjAYBgNVBAoT\nEU1hZXN0cmFubyBQdHkgTHRkMRYwFAYDVQQDEw1tYWVzdHJhbm8uY29tMSQwIgYJ\nKoZIhvcNAQkBFhVzdXBwb3J0QG1hZXN0cmFuby5jb20wHhcNMTQwMTA0MDUyNDEw\nWhcNMzMxMjMwMDUyNDEwWjCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEP\nMA0GA1UEBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQG\nA1UEAxMNbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVz\ndHJhbm8uY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQD3feNNn2xfEz5/\nQvkBIu2keh9NNhobpre8U4r1qC7h7OeInTldmxGL4cLHw4ZAqKbJVrlFWqNevM5V\nZBkDe4mjuVkK6rYK1ZK7eVk59BicRksVKRmdhXbANk/C5sESUsQv1wLZyrF5Iq8m\na9Oy4oYrIsEF2uHzCouTKM5n+O4DkwIDAQABo4HuMIHrMB0GA1UdDgQWBBSd/X0L\n/Pq+ZkHvItMtLnxMCAMdhjCBuwYDVR0jBIGzMIGwgBSd/X0L/Pq+ZkHvItMtLnxM\nCAMdhqGBjKSBiTCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEPMA0GA1UE\nBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQGA1UEAxMN\nbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVzdHJhbm8u\nY29tggkA8WlwfatbSnIwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQUFAAOBgQDE\nhe/18oRh8EqIhOl0bPk6BG49AkjhZZezrRJkCFp4dZxaBjwZTddwo8O5KHwkFGdy\nyLiPV326dtvXoKa9RFJvoJiSTQLEn5mO1NzWYnBMLtrDWojOe6Ltvn3x0HVo/iHh\nJShjAn6ZYX43Tjl1YXDd1H9O+7/VgEWAQQ32v8p5lA==\n-----END CERTIFICATE-----"
      }
    }
  end
end