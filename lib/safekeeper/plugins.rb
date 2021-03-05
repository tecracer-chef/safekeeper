require_relative "errors"

module Safekeeper
  class Plugins
    require_relative "plugins/backend"

    class << self
      # Retrieve the current plugin registry, containing all plugin names
      # and their backend handlers.
      #
      # @return [Hash] map with plugin names and plugins
      def registry
        @registry ||= {}
      end
    end
  end

  # Create a new plugin by inheriting from the class returned by this method.
  # Create a versioned plugin by providing the transport layer plugin version
  # to this method. It will then select the correct class to inherit from.
  #
  # The plugin version determines what methods will be available to your plugin.
  #
  # @param [Int] version = 1 the plugin version to use
  # @return [Transport] the versioned transport base class
  def self.plugin(plugin_type: :backend, version: 1)
    if version != 1
      raise ClientError,
        "Only understand safekeeper plugin version 1. You are trying to "\
        "initialize a safekeeper plugin #{version}, which is not supported "\
        "in the current release of safekeeper."
    end

    case plugin_type
    when :backend
      ::Safekeeper::Plugins::Backend
    else
      raise "Unknown plugin type :#{plugin_type}"
    end
  end

  # List all available plugins
  def self.plugins
    (core_backends + gem_backends).sort
  end

  def self.core_backends
    core_files = File.join(__dir__, "backends", "*.rb")

    Dir.glob(core_files).map do |full_name|
      File.basename(full_name, ".rb")
    end
  end
  private_class_method :core_backends

  def self.gem_backends
    gems = Gem::Specification.select do |gem|
      gem.name.start_with? Safekeeper::BACKEND_PLUGIN_PREFIX
    end

    gem_names = gems.map(&:name).uniq
    gem_names.map do |gem_name|
      gem_name.delete_prefix(Safekeeper::BACKEND_PLUGIN_PREFIX)
    end
  end
  private_class_method :gem_backends
end
