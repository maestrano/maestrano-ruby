module Maestrano
  module API
    class Resource < Maestrano::API::Object
      def self.class_name
        self.name.split('::').reject { |w| w.to_s == "Maestrano" }
      end

      def self.url
        if self == Maestrano::API::Resource
          raise NotImplementedError.new('Maestrano::API::Resource is an abstract class.  You should perform actions on its subclasses (Bill, Customer, etc.)')
        end
        if class_name.is_a?(Array)
          class_name.map { |w| CGI.escape(self.underscore(w)) }.join("/") + 's'
        else
          "#{CGI.escape(self.underscore(class_name))}s"
        end
      end

      def url
        unless id = self['id']
          raise Maestrano::API::Error::InvalidRequestError.new("Could not determine which URL to request: #{self.class} instance has invalid ID: #{id.inspect}", 'id')
        end
        "#{self.class.url}/#{CGI.escape(id)}"
      end

      def refresh
        response, api_token = Maestrano::API::Operation::Base.request(:get, url, @api_token, @retrieve_options)
        refresh_from(response, api_token)
        self
      end

      def self.retrieve(id, api_token=nil)
        instance = self.new(id, api_token)
        instance.refresh
        instance
      end
      
      def self.underscore(string_val)
        string_val.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
      end
    end
  end
end
