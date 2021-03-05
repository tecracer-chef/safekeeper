require "safekeeper/plugins"

require "aws-sdk-secretsmanager" unless defined?(Aws::SecretsManager)

module Safekeeper::Backends
  class AwsSecretsManager < Safekeeper.plugin
    plugin_name "aws-secretsmanager"

    option :endpoint, default: ENV["AWS_REGION"] || ENV["AWS_DEFAULT_REGION"], required: true

    # Plugin specific settings
    # none

    # For more low-level options, see https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SecretsManager/Client.html#initialize-instance_method
    option :access_key_id
    option :secret_access_key

    attr_writer :secrets_manager

    def get(secret_name, _parameters = {})
      secrets_manager.get_secret_value(secret_id: secret_name).secret_string
    rescue Aws::SecretsManager::Errors::ResourceNotFoundException => err
      raise ClientError.new(err.message)
    end

    def list(secret_prefix = "", _parameters = {})
      # TODO: Paging
      list = secrets_manager.list_secrets.secret_list

      list.reject! { |key| !key.name.start_with?(secret_prefix) }
      list.map(&:name)
    end

    def raw_backend
      vault
    end

    private

    def secrets_manager
      @secrets_manager ||= Aws::SecretsManager::Client.new(backend_options)
    end

    # Filter Safekeeper options so only valid `vault-ruby` options are left
    def backend_options
      raw_options = @options.dup

      raw_options[:http_proxy] = proxy_url
      %i{proxy_address proxy_port proxy_username proxy_password}.each { |option| raw_options.delete(option) }

      raw_options[:http_read_timeout] = raw_options[:timeout]
      raw_options.delete(:timeout)

      components = Safekeeper.unpack_target_from_uri(raw_options[:endpoint])
      raw_options[:region] = components[:host]
      raw_options.delete(:endpoint)

      raw_options
    end
  end
end
