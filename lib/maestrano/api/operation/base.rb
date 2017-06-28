module Maestrano
  module API
    module Operation
      module Base
        include Preset

        def self.api_url(url='')
          Maestrano[self.preset].param('api.host') + Maestrano[self.preset].param('api.base') + url
        end

        # Perform remote request
        def self.request(method, url, api_token, params={}, headers={})
          unless api_token ||= Maestrano[self.preset].param('api_token')
            raise Maestrano::API::Error::AuthenticationError.new('No API key provided.')
          end

          request_opts = { :verify_ssl => false }

          if self.ssl_preflight_passed?
            request_opts.update(
              verify_ssl: OpenSSL::SSL::VERIFY_PEER,
              ssl_ca_file: Maestrano[self.preset].param('ssl_bundle_path')
            )
          end

          params = Util.objects_to_ids(params)
          url = api_url(url)

          case method.to_s.downcase.to_sym
          when :get, :head, :delete
            # Make params into GET parameters
            url += "#{URI.parse(url).query ? '&' : '?'}#{uri_encode(params)}" if params && params.any?
            payload = nil
          else
            payload = uri_encode(params)
          end

          request_opts.update(:headers => request_headers(api_token).update(headers),
                              :method => method, :open_timeout => 30,
                              :payload => payload, :url => url, :timeout => 80)

          begin
            response = execute_request(request_opts)
          rescue SocketError => e
            handle_restclient_error(e)
          rescue NoMethodError => e
            # Work around RestClient bug
            if e.message =~ /\WRequestFailed\W/
              e = Maestrano::API::Error::ConnectionError.new('Unexpected HTTP response code')
              handle_restclient_error(e)
            else
              raise
            end
          rescue RestClient::ExceptionWithResponse => e
            if rcode = e.http_code and rbody = e.http_body
              handle_api_error(rcode, rbody)
            else
              handle_restclient_error(e)
            end
          rescue RestClient::Exception, Errno::ECONNREFUSED => e
            handle_restclient_error(e)
          end

          [parse(response), api_token]
        end

        private

        def self.ssl_preflight_passed?
          if !Maestrano[self.preset].param('api.verify_ssl_certs')
            #$stderr.puts "WARNING: Running without SSL cert verification. " +
            #  "Execute 'Maestrano.configure { |config| config.verify_ssl_certs = true' } to enable verification."
            return false
          elsif !Util.file_readable(Maestrano[self.preset].param('ssl_bundle_path'))
            $stderr.puts "WARNING: Running without SSL cert verification " +
              "because #{Maestrano[self.preset].param('ssl_bundle_path')} isn't readable"

            return false
          end

          return true
        end

        def self.user_agent
          @uname ||= get_uname

          {
            :bindings_version => Maestrano[self.preset].param('api.version'),
            :lang => Maestrano[self.preset].param('api.lang'),
            :lang_version => Maestrano[self.preset].param('api.lang_version'),
            :platform => RUBY_PLATFORM,
            :publisher => 'maestrano',
            :uname => @uname
          }

        end

        def self.get_uname
          `uname -a 2>/dev/null`.strip if RUBY_PLATFORM =~ /linux|darwin/i
        rescue Errno::ENOMEM => ex # couldn't create subprocess
          "uname lookup failed"
        end

        def self.uri_encode(params)
          Util.flatten_params(params).
            map { |k,v| "#{k}=#{Util.url_encode(v)}" }.join('&')
        end

        def self.request_headers(api_token)
          headers = {
            :user_agent => "Maestrano/v1 RubyBindings/#{Maestrano[self.preset].param('api.version')}",
            :authorization => "Basic #{Base64.strict_encode64(api_token)}",
            :content_type => 'application/x-www-form-urlencoded'
          }

          api_version = Maestrano[self.preset].param('api_version')
          headers[:maestrano_version] = api_version if api_version

          begin
            headers.update(:x_maestrano_client_user_agent => JSON.generate(user_agent))
          rescue => e
            headers.update(:x_maestrano_client_raw_user_agent => user_agent.inspect,
                           :error => "#{e} (#{e.class})")
          end
        end

        def self.execute_request(opts)
          RestClient::Request.execute(opts)
        end

        def self.parse(response)
          begin
            # Would use :symbolize_names => true, but apparently there is
            # some library out there that makes symbolize_names not work.
            response = JSON.parse(response.body)
          rescue JSON::ParserError
            raise general_api_error(response.code, response.body)
          end

          response = Util.symbolize_names(response)
          response[:data]
        end

        def self.general_api_error(rcode, rbody)
          Maestrano::API::Error::BaseError.new("Invalid response object from API: #{rbody.inspect} " +
                       "(HTTP response code was #{rcode})", rcode, rbody)
        end

        def self.handle_api_error(rcode, rbody)
          begin
            error_obj = JSON.parse(rbody)
            error_obj = Util.symbolize_names(error_obj)
            errors = error_obj[:errors] or raise Maestrano::API::Error::BaseError.new # escape from parsing

          rescue JSON::ParserError, Maestrano::API::Error::BaseError
            raise general_api_error(rcode, rbody)
          end

          case rcode
          when 400, 404
            raise invalid_request_error(errors, rcode, rbody, error_obj)
          when 401
            raise authentication_error(errors, rcode, rbody, error_obj)
          else
            raise api_error(errors, rcode, rbody, error_obj)
          end

        end

        def self.invalid_request_error(errors, rcode, rbody, error_obj)
          Maestrano::API::Error::InvalidRequestError.new(errors.first.join(" "), errors.keys.first.to_s, rcode,
                                  rbody, error_obj)
        end

        def self.authentication_error(errors, rcode, rbody, error_obj)
          Maestrano::API::Error::AuthenticationError.new(errors.first.join(" "), rcode, rbody, error_obj)
        end

        def self.api_error(errors, rcode, rbody, error_obj)
          Maestrano::API::Error::BaseError.new(errors[:message], rcode, rbody, error_obj)
        end

        def self.handle_restclient_error(e)
          case e
          when RestClient::ServerBrokeConnection, RestClient::RequestTimeout
            message = "Could not connect to Maestrano. " +
              "Please check your internet connection and try again. " +
              "If this problem persists, you should check Maestrano service status at " +
              "https://twitter.com/maestrano, or let us know at support@maestrano.com."

          when RestClient::SSLCertificateNotVerified
            message = "Could not verify Maestrano's SSL certificate. " +
              "Please make sure that your network is not intercepting certificates. " +
              "(Try going to https://maestrano.com/api/v1/ping in your browser.) " +
              "If this problem persists, let us know at support@maestrano.com."

          when SocketError
            message = "Unexpected error communicating when trying to connect to Maestrano. " +
              "You may be seeing this message because your DNS is not working. " +
              "To check, try running 'host maestrano.com' from the command line."

          else
            message = "Unexpected error communicating with Maestrano. " +
              "If this problem persists, let us know at support@maestrano.com."

          end

          raise Maestrano::API::Error::ConnectionError.new(message + "\n\n(Network error: #{e.message})")
        end
      end
    end
  end
end
