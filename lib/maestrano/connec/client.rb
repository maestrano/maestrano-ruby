module Maestrano
  module Connec
    
    class Client
      include HTTParty
      base_uri 'localhost:8080'
      headers 'Accept' => 'application/vnd.api+json'
      headers 'Content-Type' => 'application/vnd.api+json'
      format :json
      
      attr_reader :group_id
      
      def initialize(group_id)
        @group_id = group_id

      end
      
      # Return the base options including
      # authentication
      def options
        {
          basic_auth: { 
            username: Maestrano.param('api_id'), 
            password: Maestrano.param('api_key')
          } 
        }
      end
      
      def 
      
    end
    
  end
end