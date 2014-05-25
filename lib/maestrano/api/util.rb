module Maestrano
  module API
    module Util
      def self.objects_to_ids(h)
        case h
        when Maestrano::API::Resource
          h.id
        when Hash
          res = {}
          h.each { |k, v| res[k] = objects_to_ids(v) unless v.nil? }
          res
        when Array
          h.map { |v| objects_to_ids(v) }
        else
          h
        end
      end

      def self.object_classes
        @object_classes ||= {
          'account_bill' => Maestrano::Account::Bill,
          'internal_list_object' => Maestrano::API::ListObject
        }
      end

      def self.convert_to_maestrano_object(resp, api_key)
        case resp
        when Array
          if resp.empty? || !resp.first[:object]
            resp
          else
            list = convert_to_maestrano_object({
              object: 'internal_list_object', 
              data:[],
              url: convert_to_maestrano_object(resp.first, api_key).class.url
            },api_key)
            
            resp.each do |i|
              list.data.push(convert_to_maestrano_object(i, api_key))
            end
            list
          end
        when Hash
          # Try converting to a known object class.  If none available, fall back to generic Maestrano::API::Object
          object_classes.fetch(resp[:object], Maestrano::API::Object).construct_from(resp, api_key)
        else
          resp
        end
      end

      def self.file_readable(file)
        # This is nominally equivalent to File.readable?, but that can
        # report incorrect results on some more oddball filesystems
        # (such as AFS)
        begin
          File.open(file) { |f| }
        rescue
          false
        else
          true
        end
      end

      def self.symbolize_names(object)
        case object
        when Hash
          new = {}
          object.each do |key, value|
            key = (key.to_sym rescue key) || key
            new[key] = symbolize_names(value)
          end
          new
        when Array
          object.map { |value| symbolize_names(value) }
        else
          object
        end
      end

      def self.url_encode(key)
        URI.escape(key.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      end

      def self.flatten_params(params, parent_key=nil)
        result = []
        params.each do |key, value|
          calculated_key = parent_key ? "#{parent_key}[#{url_encode(key)}]" : url_encode(key)
          if value.is_a?(Hash)
            result += flatten_params(value, calculated_key)
          elsif value.is_a?(Array)
            result += flatten_params_array(value, calculated_key)
          else
            result << [calculated_key, value]
          end
        end
        result
      end

      def self.flatten_params_array(value, calculated_key)
        result = []
        value.each do |elem|
          if elem.is_a?(Hash)
            result += flatten_params(elem, calculated_key)
          elsif elem.is_a?(Array)
            result += flatten_params_array(elem, calculated_key)
          else
            result << ["#{calculated_key}[]", elem]
          end
        end
        result
      end
    end
  end
end