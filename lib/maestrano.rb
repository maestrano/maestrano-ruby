# libs
require 'rest_client'
require 'json'

# OpenStruct (Extended)
require 'ostruct'
require 'maestrano/open_struct'

# Version
require 'maestrano/version'

# Multiple providers support
require 'maestrano/preset'

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
require 'maestrano/account/user'
require 'maestrano/account/group'
require 'maestrano/account/bill'
require 'maestrano/account/recurring_bill'

# Connec
require 'maestrano/connec/client'

module Maestrano
  include Preset
  
  class << self
    attr_accessor :configs
  end
  
  # Maestrano Configuration block
  def self.configure
    self.configs ||= {}
    self.configs[preset] ||= Configuration.new
    yield(configs[preset])
    self.configs[preset].post_initialize
    return self
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
    if self.param('sso.creation_mode') == 'virtual'
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
  # Maestrano.param('api.key')
  # Maestrano.param(:api_key)
  # Maestrano['preset'].param('api.key')
  def self.param(parameter)
    (self.configs[preset] || Configuration.new).param(parameter)
  end
  
  # Return a hash describing the current
  # Maestrano configuration. The metadata
  # will be remotely fetched by Maestrano
  # Exclude any info containing an api key
  def self.to_metadata
    hash = {}
    hash['environment'] = self.param('environment')
    
    config_groups = ['app','api','sso','webhook']
    blacklist = ['api.key','api.token']
    
    config_groups.each do |cgroup_name|
      cgroup = self.configs[preset].send(cgroup_name)
      
      attr_list = cgroup.attributes.map(&:to_s)
      attr_list += Configuration::EVT_CONFIG[hash['environment']].keys.select { |k| k =~ Regexp.new("^#{cgroup_name}\.") }.map { |k| k.gsub(Regexp.new("^#{cgroup_name}\."),'') }
      attr_list.uniq!
      
      attr_list.each do |first_lvl|
        if cgroup.send(first_lvl).is_a?(OpenStruct)
          c2group = cgroup.send(first_lvl)
          c2group.attributes.each do |secnd_lvl|
            full_param = [cgroup_name,first_lvl,secnd_lvl].join('.')
            unless blacklist.include?(full_param)
              hash[cgroup_name.to_s] ||= {}
              hash[cgroup_name.to_s][first_lvl.to_s] ||= {}
              hash[cgroup_name.to_s][first_lvl.to_s][secnd_lvl.to_s] = self.param(full_param)
            end
          end
        else
          full_param = [cgroup_name,first_lvl].join('.')
          unless blacklist.include?(full_param)
            hash[cgroup_name.to_s] ||= {}
            hash[cgroup_name.to_s][first_lvl.to_s] = self.param(full_param)
          end
        end
      end
    end
    
    return hash
  end

  class Configuration
    attr_accessor :environment, :app, :sso, :api, :webhook, :connec

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
        lang: nil, #set in post_initialize
        lang_version: nil #set in post_initialize
      })
      
      # SSO Config
      @sso = OpenStruct.new({
        enabled: true,
        slo_enabled: true,
        creation_mode: 'real',
        init_path: '/maestrano/auth/saml/init',
        consume_path: '/maestrano/auth/saml/consume',
        idm: nil
      })
      
      # WebHooks Config
      @webhook = OpenStruct.new({
        account: OpenStruct.new({
          groups_path: '/maestrano/account/groups/:id',
          group_users_path: '/maestrano/account/groups/:group_id/users/:id',
        }),
        connec: OpenStruct.new({
          notifications_path: '/maestrano/connec/notifications',
          subscriptions: {}
        })
      })

      # Connec! Config
      @connec = OpenStruct.new({
        enabled: true
      })
    end
    
    # Force or default certain parameters
    # Used after configure block
    def post_initialize
      self.api.token = "#{self.api.id}:#{self.api.key}"
      self.api.version = Maestrano::VERSION
      self.api.lang = 'ruby'
      self.api.lang_version = "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE})"
      self.sso.idm ||= self.app.host
      self.sso.slo_enabled &&= self.sso.enabled
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
        props = new_meth.split('.')
        last_prop = props.pop
        obj = props.inject(self,:send)
        obj.send(last_prop, *args, &block)
      else
        super
      end
    end
    
    # Get configuration parameter value
    def param(parameter)
      real_param = self.legacy_param_to_new(parameter)
      props = real_param.split('.')
      
      # Either respond to param directly or via properties chaining (e.g: webhook.account.groups_path)
      if self.respond_to?(real_param) || props.inject(self) { |result,elem| result && result.respond_to?(elem) ? result.send(elem) || elem : false }
        last_prop = props.pop
        obj = props.inject(self,:send)
        obj.send(last_prop)
      elsif EVT_CONFIG[@environment.to_s].has_key?(real_param.to_s)
        EVT_CONFIG[@environment.to_s][real_param.to_s]
      else
        raise ArgumentError, "No such configuration parameter: '#{parameter}'"
      end
    end
    
    EVT_CONFIG = {
      'local' => {
        'api.host'             => 'http://application.maestrano.io',
        'api.base'             => '/api/v1/',
        'connec.enabled'       => true,
        'connec.host'          => 'http://connec.maestrano.io',
        'connec.base_path'     => '/api/v2',
        'connec.v2_path'       => '/v2',
        'connec.reports_path'  => '/reports',
        'connec.timeout'       => 60,
        'sso.idp'              => 'http://application.maestrano.io',
        'sso.name_id_format'   => Maestrano::Saml::Settings::NAMEID_PERSISTENT,
        'sso.x509_fingerprint' => '01:06:15:89:25:7d:78:12:28:a6:69:c7:de:63:ed:74:21:f9:f5:36',
        'sso.x509_certificate' => "-----BEGIN CERTIFICATE-----\nMIIDezCCAuSgAwIBAgIJAOehBr+YIrhjMA0GCSqGSIb3DQEBBQUAMIGGMQswCQYD\nVQQGEwJBVTEMMAoGA1UECBMDTlNXMQ8wDQYDVQQHEwZTeWRuZXkxGjAYBgNVBAoT\nEU1hZXN0cmFubyBQdHkgTHRkMRYwFAYDVQQDEw1tYWVzdHJhbm8uY29tMSQwIgYJ\nKoZIhvcNAQkBFhVzdXBwb3J0QG1hZXN0cmFuby5jb20wHhcNMTQwMTA0MDUyMjM5\nWhcNMzMxMjMwMDUyMjM5WjCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEP\nMA0GA1UEBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQG\nA1UEAxMNbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVz\ndHJhbm8uY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDVkIqo5t5Paflu\nP2zbSbzxn29n6HxKnTcsubycLBEs0jkTkdG7seF1LPqnXl8jFM9NGPiBFkiaR15I\n5w482IW6mC7s8T2CbZEL3qqQEAzztEPnxQg0twswyIZWNyuHYzf9fw0AnohBhGu2\n28EZWaezzT2F333FOVGSsTn1+u6tFwIDAQABo4HuMIHrMB0GA1UdDgQWBBSvrNxo\neHDm9nhKnkdpe0lZjYD1GzCBuwYDVR0jBIGzMIGwgBSvrNxoeHDm9nhKnkdpe0lZ\njYD1G6GBjKSBiTCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEPMA0GA1UE\nBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQGA1UEAxMN\nbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVzdHJhbm8u\nY29tggkA56EGv5giuGMwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQUFAAOBgQCc\nMPgV0CpumKRMulOeZwdpnyLQI/NTr3VVHhDDxxCzcB0zlZ2xyDACGnIG2cQJJxfc\n2GcsFnb0BMw48K6TEhAaV92Q7bt1/TYRvprvhxUNMX2N8PHaYELFG2nWfQ4vqxES\nRkjkjqy+H7vir/MOF3rlFjiv5twAbDKYHXDT7v1YCg==\n-----END CERTIFICATE-----"
      },
      'test' => {
        'api.host'             => 'http://api-sandbox.maestrano.io',
        'api.base'             => '/api/v1/',
        'connec.enabled'       => true,
        'connec.host'          => 'http://api-sandbox.maestrano.io',
        'connec.base_path'     => '/connec/api/v2',
        'connec.v2_path'       => '/v2',
        'connec.reports_path'  => '/reports',
        'connec.timeout'       => 60,
        'sso.idp'              => 'https://maestrano.com',
        'sso.name_id_format'   => Maestrano::Saml::Settings::NAMEID_PERSISTENT,
        'sso.x509_fingerprint' => '01:06:15:89:25:7d:78:12:28:a6:69:c7:de:63:ed:74:21:f9:f5:36',
        'sso.x509_certificate' => "-----BEGIN CERTIFICATE-----\nMIIDezCCAuSgAwIBAgIJAOehBr+YIrhjMA0GCSqGSIb3DQEBBQUAMIGGMQswCQYD\nVQQGEwJBVTEMMAoGA1UECBMDTlNXMQ8wDQYDVQQHEwZTeWRuZXkxGjAYBgNVBAoT\nEU1hZXN0cmFubyBQdHkgTHRkMRYwFAYDVQQDEw1tYWVzdHJhbm8uY29tMSQwIgYJ\nKoZIhvcNAQkBFhVzdXBwb3J0QG1hZXN0cmFuby5jb20wHhcNMTQwMTA0MDUyMjM5\nWhcNMzMxMjMwMDUyMjM5WjCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEP\nMA0GA1UEBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQG\nA1UEAxMNbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVz\ndHJhbm8uY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDVkIqo5t5Paflu\nP2zbSbzxn29n6HxKnTcsubycLBEs0jkTkdG7seF1LPqnXl8jFM9NGPiBFkiaR15I\n5w482IW6mC7s8T2CbZEL3qqQEAzztEPnxQg0twswyIZWNyuHYzf9fw0AnohBhGu2\n28EZWaezzT2F333FOVGSsTn1+u6tFwIDAQABo4HuMIHrMB0GA1UdDgQWBBSvrNxo\neHDm9nhKnkdpe0lZjYD1GzCBuwYDVR0jBIGzMIGwgBSvrNxoeHDm9nhKnkdpe0lZ\njYD1G6GBjKSBiTCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEPMA0GA1UE\nBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQGA1UEAxMN\nbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVzdHJhbm8u\nY29tggkA56EGv5giuGMwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQUFAAOBgQCc\nMPgV0CpumKRMulOeZwdpnyLQI/NTr3VVHhDDxxCzcB0zlZ2xyDACGnIG2cQJJxfc\n2GcsFnb0BMw48K6TEhAaV92Q7bt1/TYRvprvhxUNMX2N8PHaYELFG2nWfQ4vqxES\nRkjkjqy+H7vir/MOF3rlFjiv5twAbDKYHXDT7v1YCg==\n-----END CERTIFICATE-----",
      },
      'uat' => {
        'api.host'             => 'https://uat.maestrano.io',
        'api.base'             => '/api/v1/',
        'connec.enabled'       => true,
        'connec.host'          => 'https://api-connec-uat.maestrano.io',
        'connec.base_path'     => '/api/v2',
        'connec.v2_path'       => '/v2',
        'connec.reports_path'  => '/reports',
        'connec.timeout'       => 180,
        'sso.idp'              => 'https://uat.maestrano.io',
        'sso.name_id_format'   => Maestrano::Saml::Settings::NAMEID_PERSISTENT,
        'sso.x509_fingerprint' => '8a:1e:2e:76:c4:67:80:68:6c:81:18:f7:d3:29:5d:77:f8:79:54:2f',
        'sso.x509_certificate' => "-----BEGIN CERTIFICATE-----\nMIIDezCCAuSgAwIBAgIJAMzy+weDPp7qMA0GCSqGSIb3DQEBBQUAMIGGMQswCQYD\nVQQGEwJBVTEMMAoGA1UECBMDTlNXMQ8wDQYDVQQHEwZTeWRuZXkxGjAYBgNVBAoT\nEU1hZXN0cmFubyBQdHkgTHRkMRYwFAYDVQQDEw1tYWVzdHJhbm8uY29tMSQwIgYJ\nKoZIhvcNAQkBFhVzdXBwb3J0QG1hZXN0cmFuby5jb20wHhcNMTQwMTA0MDUyMzE0\nWhcNMzMxMjMwMDUyMzE0WjCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEP\nMA0GA1UEBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQG\nA1UEAxMNbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVz\ndHJhbm8uY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC+2uyQeAOc/iro\nhCyT33RkkWfTGeJ8E/mu9F5ORWoCZ/h2J+QDuzuc69Rf1LoO4wZVQ8LBeWOqMBYz\notYFUIPlPfIBXDNL/stHkpg28WLDpoJM+46WpTAgp89YKgwdAoYODHiUOcO/uXOO\n2i9Ekoa+kxbvBzDJf7uuR/io6GERXwIDAQABo4HuMIHrMB0GA1UdDgQWBBTGRDBT\nie5+fHkB0+SZ5g3WY/D2RTCBuwYDVR0jBIGzMIGwgBTGRDBTie5+fHkB0+SZ5g3W\nY/D2RaGBjKSBiTCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEPMA0GA1UE\nBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQGA1UEAxMN\nbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVzdHJhbm8u\nY29tggkAzPL7B4M+nuowDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQUFAAOBgQAw\nRxg3rZrML//xbsS3FFXguzXiiNQAvA4KrMWhGh3jVrtzAlN1/okFNy6zuN8gzdKD\nYw2n0c/u3cSpUutIVZOkwQuPCMC1hoP7Ilat6icVewNcHayLBxKgRxpBhr5Sc4av\n3HOW5Bi/eyC7IjeBTbTnpziApEC7uUsBou2rlKmTGw==\n-----END CERTIFICATE-----"
      },
      'production' => {
        'api.host'             => 'https://maestrano.com',
        'api.base'             => '/api/v1/',
        'connec.enabled'       => true,
        'connec.host'          => 'https://api-connec.maestrano.com',
        'connec.base_path'     => '/api/v2',
        'connec.v2_path'       => '/v2',
        'connec.reports_path'  => '/reports',
        'connec.timeout'       => 180,
        'sso.idp'              => 'https://maestrano.com',
        'sso.name_id_format'   => Maestrano::Saml::Settings::NAMEID_PERSISTENT,
        'sso.x509_fingerprint' => '2f:57:71:e4:40:19:57:37:a6:2c:f0:c5:82:52:2f:2e:41:b7:9d:7e',
        'sso.x509_certificate' => "-----BEGIN CERTIFICATE-----\nMIIDezCCAuSgAwIBAgIJAPFpcH2rW0pyMA0GCSqGSIb3DQEBBQUAMIGGMQswCQYD\nVQQGEwJBVTEMMAoGA1UECBMDTlNXMQ8wDQYDVQQHEwZTeWRuZXkxGjAYBgNVBAoT\nEU1hZXN0cmFubyBQdHkgTHRkMRYwFAYDVQQDEw1tYWVzdHJhbm8uY29tMSQwIgYJ\nKoZIhvcNAQkBFhVzdXBwb3J0QG1hZXN0cmFuby5jb20wHhcNMTQwMTA0MDUyNDEw\nWhcNMzMxMjMwMDUyNDEwWjCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEP\nMA0GA1UEBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQG\nA1UEAxMNbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVz\ndHJhbm8uY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQD3feNNn2xfEz5/\nQvkBIu2keh9NNhobpre8U4r1qC7h7OeInTldmxGL4cLHw4ZAqKbJVrlFWqNevM5V\nZBkDe4mjuVkK6rYK1ZK7eVk59BicRksVKRmdhXbANk/C5sESUsQv1wLZyrF5Iq8m\na9Oy4oYrIsEF2uHzCouTKM5n+O4DkwIDAQABo4HuMIHrMB0GA1UdDgQWBBSd/X0L\n/Pq+ZkHvItMtLnxMCAMdhjCBuwYDVR0jBIGzMIGwgBSd/X0L/Pq+ZkHvItMtLnxM\nCAMdhqGBjKSBiTCBhjELMAkGA1UEBhMCQVUxDDAKBgNVBAgTA05TVzEPMA0GA1UE\nBxMGU3lkbmV5MRowGAYDVQQKExFNYWVzdHJhbm8gUHR5IEx0ZDEWMBQGA1UEAxMN\nbWFlc3RyYW5vLmNvbTEkMCIGCSqGSIb3DQEJARYVc3VwcG9ydEBtYWVzdHJhbm8u\nY29tggkA8WlwfatbSnIwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQUFAAOBgQDE\nhe/18oRh8EqIhOl0bPk6BG49AkjhZZezrRJkCFp4dZxaBjwZTddwo8O5KHwkFGdy\nyLiPV326dtvXoKa9RFJvoJiSTQLEn5mO1NzWYnBMLtrDWojOe6Ltvn3x0HVo/iHh\nJShjAn6ZYX43Tjl1YXDd1H9O+7/VgEWAQQ32v8p5lA==\n-----END CERTIFICATE-----",
      }
    }
  end
end