require_relative "safekeeper/constants"
require_relative "safekeeper/errors"
require_relative "safekeeper/plugins"
require_relative "safekeeper/structures"
require_relative "safekeeper/version"

require "addressable/uri" unless defined?(Addressable::URI)

# Automatically integrate into tools
require "integrations/chef_dsl" if defined?(Chef)

module Safekeeper
  # Create a new backend instance, with the plugin indicated by the
  # given name.
  #
  # @param [String] name of the plugin
  # @param [Array] *args list of arguments for the plugin
  # @return [Backend] instance of the new backend or nil
  def self.create(name, *args)
    cls = load_backend(name)
    cls.new(*args) unless cls.nil?
  end

  # Retrieve the configuration options of a backend plugin.
  #
  # @param [String] name of the plugin
  # @return [Hash] map of default options
  def self.options(name)
    cls = load_backend(name)
    cls.default_options unless cls.nil?
  end

  # Load the backend plugin indicated by name. If the plugin is not
  # yet found in the plugin registry, it will be attempted to load from
  # `safekeeper/backend/plugin_name`.00
  #
  # @param [String] name of the plugin
  # @return [Safekeeper::Backend] the backend plugin
  def self.load_backend(backend_name)
    backend_name = backend_name.to_s
    backend_class = Safekeeper::Plugins.registry[backend_name]
    return backend_class unless backend_class.nil?

    # Try to load the backend name from the core backend...
    require_relative File.join(Safekeeper::BACKEND_PLUGIN_PATH, backend_name)
    Safekeeper::Plugins.registry[backend_name]
  rescue LoadError => _
    begin
      # If it's not in the core backends, try loading from a safekeeper plugin gem.
      gem_name = Safekeeper::BACKEND_PLUGIN_PREFIX + backend_name
      require gem_name
      return Safekeeper::Plugins.registry[backend_name]
      # rubocop: disable Lint/HandleExceptions
    rescue LoadError => _
      # rubocop: enable Lint/HandleExceptions
      # Intentionally empty rescue - we're handling it below anyway
    end

    ex = Safekeeper::PluginLoadError.new("Can't find safekeeper plugin #{backend_name}. Please install it first.")
    ex.backend_name = backend_name
    raise ex
  end

  # Given a string that looks like a URI, unpack connection credentials.
  # The name of the desired backend is always taken from the 'scheme' slot of the URI;
  # the remaining portion of the URI is parsed as if it were an HTTP URL, and then
  # the URL components are stored in the credentials hash.  It is up to the backend
  # to interpret the fields in a sensible way for that backend.
  def self.unpack_target_from_uri(uri_string, opts = {})
    creds = {}
    return creds if uri_string.empty?

    # split up the target's host/scheme configuration
    uri = parse_uri(uri_string)
    unless uri.host.nil? && uri.scheme.nil?
      creds[:backend]  ||= uri.scheme
      creds[:host]     ||= uri.hostname
      creds[:port]     ||= uri.port
      creds[:user]     ||= uri.user
      creds[:path]     ||= uri.path
      # TODO: query, fragment?
      creds[:password] ||=
        if opts[:www_form_encoded_password] && !uri.password.nil?
          Addressable::URI.unencode_component(uri.password)
        else
          uri.password
        end
    end

    creds
  end

  # Parse a URI. Supports empty URI's with paths, e.g. `mock://`
  #
  # @param string [string] URI string, e.g. `schema://domain.com`
  # @return [Addressable::URI] parsed URI object
  def self.parse_uri(string)
    u = Addressable::URI.parse(string)
    # A use-case we want to catch is parsing empty URIs with a schema
    # e.g. mock://. To do this, we match it manually and fake the hostname
    if u.scheme && (u.host.nil? || u.host.empty?) && u.path.empty?
      case string
      when %r{^([a-z]+)://$}
        string += "dummy"
      when /^([a-z]+):$/
        string += "//dummy"
      end
      u = Addressable::URI.parse(string)
      u.host = nil
    end
    u
  rescue Addressable::URI::InvalidURIError => e
    raise Safekeeper::UserError, e
  end
  private_class_method :parse_uri
end
