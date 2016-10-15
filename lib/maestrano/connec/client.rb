require 'httparty'

module Maestrano
  module Connec
    class Client
      include Preset
      include ::HTTParty
      headers 'Accept' => 'application/vnd.api+json'
      headers 'Content-Type' => 'application/vnd.api+json'
      format :json

      attr_reader :group_id

      def initialize(group_id)
        @group_id = group_id
        @debug = !!ENV['DEBUG_CONNEC']

        self.class.base_uri("#{Maestrano[self.class.preset].param('connec.host')}#{Maestrano[self.class.preset].param('connec.base_path')}")
      end

      # Return the default options which includes
      # maestrano authentication
      def default_options
        {
          basic_auth: {
            username: Maestrano[self.class.preset].param('api.id'),
            password: Maestrano[self.class.preset].param('api.key')
          },
          timeout: Maestrano[self.class.preset].param('connec.timeout')
        }
      end

      # Return the right path scoped using the customer
      # group id
      def scoped_path(relative_path)
        clean_path = relative_path.gsub(/^\/+/, "").gsub(/\/+$/, "")
        "/#{@group_id}/#{clean_path}"
      end

      # E.g: client.get('/organizations')
      # E.g: client.get('/organizations/123')
      def get(relative_path, options = {})
        url = self.scoped_path(relative_path)
        response = self.class.get(url, default_options.merge(options))

        save_request_response(:get, url, nil, response) if @debug

        response
      end

      # E.g: client.post('/organizations', { organizations: { name: 'DoeCorp Inc.' } })
      def post(relative_path, body, options = {})
        url = self.scoped_path(relative_path)
        response = self.class.post(url, default_options.merge(body: body.to_json).merge(options))

        save_request_response(:post, url, body.to_json, response) if @debug

        response
      end

      # E.g for collection:
      # => client.put('/organizations/123', { organizations: { name: 'DoeCorp Inc.' } })
      # E.g for singular resource:
      # => client.put('/company', { company: { name: 'DoeCorp Inc.' } })
      def put(relative_path, body, options = {})
        url = self.scoped_path(relative_path)
        response = self.class.put(url, default_options.merge(body: body.to_json).merge(options))

        save_request_response(:put, url, body.to_json, response) if @debug

        response
      end

      def batch(body, options = {})
        url = "#{Maestrano[self.class.preset].param('connec.host')}/batch"
        response = self.class.post(url, default_options.merge(body: body.to_json).merge(options))

        save_request_response(:post, '/batch', body.to_json, response) if @debug

        response
      end

      # Save request/response files
      # * GET
      #   request:  /tmp/connec/get/cld-123/organizations/XYZ/request
      #   response: /tmp/connec/get/cld-123/organizations/XYZ/response
      # * POST
      #   request:  /tmp/connec/post/cld-123/organizations/XYZ/request
      #   response: /tmp/connec/post/cld-123/organizations/XYZ/response
      # * PUT
      #   request:  /tmp/connec/put/cld-123/organizations/XYZ/request
      #   response: /tmp/connec/put/cld-123/organizations/XYZ/response
      def save_request_response(action, url, request_body, response)
        # Path to store files
        file_path = "#{Dir.tmpdir}/connec/#{action}#{url}/#{SecureRandom.hex}"
        FileUtils.mkdir_p(file_path)

        # Save request and response
        File.open("#{file_path}/request", 'w') { |file| file.write(request_body) }
        File.open("#{file_path}/response", 'w') { |file| file.write(response.body) }
      end
    end
  end
end
