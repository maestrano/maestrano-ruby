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
        self.class.get(self.scoped_path(relative_path),default_options.merge(options))
      end
      
      # E.g: client.post('/organizations', { organizations: { name: 'DoeCorp Inc.' } })
      def post(relative_path, body, options = {})
        self.class.post(self.scoped_path(relative_path),
          default_options.merge(body: body.to_json).merge(options)
        )
      end
      
      # E.g for collection: 
      # => client.put('/organizations/123', { organizations: { name: 'DoeCorp Inc.' } })
      # E.g for singular resource: 
      # => client.put('/company', { company: { name: 'DoeCorp Inc.' } })
      def put(relative_path, body, options = {})
        self.class.put(self.scoped_path(relative_path),
          default_options.merge(body: body.to_json).merge(options)
        )
      end

      def batch(body, options = {})
        self.class.post("#{Maestrano[self.class.preset].param('connec.host')}/batch", default_options.merge(body: body.to_json).merge(options))
      end
    end
  end
end