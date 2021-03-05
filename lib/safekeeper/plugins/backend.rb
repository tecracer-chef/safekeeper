require "logger"

require_relative "../constants"
require_relative "../errors"
require_relative "../options"
# require_relative "../structures"

require "hashie" unless defined?(Hashie)

class Safekeeper::Plugins
  class Backend
    # include Safekeeper::Structures
    Safekeeper::Options.attach(self)

    # Common Backend plugin options across plugins
    option :endpoint, required: true # TODO: aws-sm://eu-central-1 (endpoint = region?)
    option :timeout, default: 30
    option :ssl_verify, default: true

    option :proxy_address
    option :proxy_port
    option :proxy_username
    option :proxy_password

    # Initialize a new Backend object
    #
    # @param [Hash] config = nil the configuration for this backend
    # @return [Backend] the backend object
    def initialize(options = {})
      @options = merge_options({}, options || {})

      @logger = @options[:logger] || Logger.new($stdout, level: :fatal)
    end

    # Register the inheriting class with as a safekeeper plugin using the
    # provided name.
    #
    # @param [String] name of the plugin, by which it will be found
    def self.plugin_name(name)
      Safekeeper::Plugins.registry[name] = self
    end

    def uri
      components = Safekeeper.unpack_target_from_uri(@options[:endpoint])

      format("%<backend>s://%<user_str>s%<host>s%<port_str>s%<path_str>s",
        components.merge(
          user_str: components[:user] ? "#{components[:user]}@" : "",
          port_str: components[:port] ? ":#{components[:port]}" : "",
          path_str: components[:path].empty? ? "" : "/#{components[:path]}"
        )
      )
    end

    def raw_backend
      raise NotImplementedError, "Plugin #{plugin_name} does not implement the get method"
    end

    # Needs to always return data as string for consistency (dump JSON, if native return type)
    def get(secret_name, parameters = {})
      raise NotImplementedError, "Plugin #{plugin_name} does not implement the get method"
    end

    def list(secret_prefix, parameters = {})
      raise NotImplementedError, "Plugin #{plugin_name} does not implement the list method"
    end

    def put(secret_name, data, parameters = {})
      raise NotImplementedError, "Plugin #{plugin_name} does not implement the put method"
    end

    def delete(secret_name, parameters = {})
      raise NotImplementedError, "Plugin #{plugin_name} does not implement the delete method"
    end

    def patch(secret_name, parameters = {})
      raise NotImplementedError, "Plugin #{plugin_name} does not implement the patch method"
    end

    private

    # @return [Logger] logger for reporting information
    attr_reader :logger

    def proxy_url
      return nil unless @options[:proxy_address]

      proxy = URI.parse(@options[:proxy_address])
      proxy.port = @options[:proxy_port] if @options[:proxy_port]
      proxy.user = @options[:proxy_username] if @options[:proxy_username]
      proxy.password = @options[:proxy_password] if @options[:proxy_password]

      proxy.to_s
    end
  end
end
