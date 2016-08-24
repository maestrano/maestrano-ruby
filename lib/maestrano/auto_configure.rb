module Maestrano
  module AutoConfigure
    def self.get_marketplace_configurations(config_file_path = nil)
      devpl_config = dev_platform_config(config_file_path)

      begin
        request = RestClient::Request.new(
          method: :get,
          url: "#{devpl_config[:host]}#{devpl_config[:v1_path]}",
          user: devpl_config[:api_key],
          password: devpl_config[:api_secret],
          headers: {
            accept: :json
          }
        )
        response = request.execute
        response = JSON.parse(response.to_s)
      rescue => e
        #Do something
        raise e
      end

      response['marketplaces'].each do |marketplace|
        Maestrano[marketplace['marketplace']].configure do |config|
          config.environment = h[:environment]

          [:app, :sso, :api, :webhook, :connec].each do |s|
            config.send(s).marshal_load(hash.inject(response[s.to_s] || {}) { |h, (k,v)| h[k.to_sym] = v; h })
          end
        end
      end
    end

    def self.dev_platform_config(config_file_path = nil)
      begin
        yaml_config = YAML.load_file(Rails.root.join(config_file_path))
      rescue 
        yaml_config = {dev_platform: {}}
      end

      devpl_config = {}
      devpl_config[:host] = ENV['MNO_DEVPL_HOST'] || yaml_config[:dev_platform][:host]
      devpl_config[:v1_path] = ENV['MNO_DEVPL_V1_PATH'] || yaml_config[:dev_platform][:v1_path]

      devpl_config[:environment] = ENV['MNO_DEVPL_ENVIRONMENT_NAME'] || yaml_config[:dev_platform][:environment]
      devpl_config[:api_key] = ENV['MNO_DEVPL_KEY'] || yaml_config[:dev_platform][:api_key]
      devpl_config[:api_secret] = ENV['MNO_DEVPL_SECRET'] || yaml_config[:dev_platform][:api_secret]

      raise 'Nope' if devpl_config.values.find { |v| v.nil? || v.empty? }

      devpl_config
    end
  end
end
