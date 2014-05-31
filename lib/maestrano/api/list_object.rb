module Maestrano
  module API
    class ListObject < Maestrano::API::Object

      def [](k)
        case k
        when String, Symbol
          super
        else
          raise ArgumentError.new("You tried to access the #{k.inspect} index, but ListObject types only support String keys. (HINT: List calls return an object with a 'data' (which is the data array). You likely want to call #data[#{k.inspect}])")
        end
      end

      def each(&blk)
        self.data.each(&blk)
      end

      def retrieve(id, api_token=nil)
        api_token ||= @api_token
        response, api_token = Maestrano::API::Operation::Base.request(:get,"#{url}/#{CGI.escape(id)}", api_token)
        Util.convert_to_maestrano_object(response, api_token)
      end

      def create(params={}, api_token=nil)
        api_token ||= @api_token
        response, api_token = Maestrano::API::Operation::Base.request(:post, url, api_token, params)
        Util.convert_to_maestrano_object(response, api_token)
      end

      def all(params={}, api_token=nil)
        api_token ||= @api_token
        response, api_token = Maestrano::API::Operation::Base.request(:get, url, api_token, params)
        Util.convert_to_maestrano_object(response, api_token)
      end
    end
  end
end
