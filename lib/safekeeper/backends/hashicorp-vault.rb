require "safekeeper/plugins"

require "vault" unless defined?(Vault)

module Safekeeper::Backends
  class HashicorpVault < Safekeeper.plugin
    plugin_name "hashicorp-vault"

    option :endpoint, default: ENV["VAULT_ADDR"], required: true

    # Plugin specific settings
    option :engine, default: "secret", required: true
    option :engine_type, default: "kv2"
    option :prefix, default: "/" # TODO

    # For more low-level options, see https://github.com/hashicorp/vault-ruby
    option :token, default: ENV["VAULT_TOKEN"], required: true
    option :timeout, default: 30
    option :ssl_verify, default: ENV["VAULT_SSL_VERIFY"] || true
    # ...

    class VaultNotFoundError < Safekeeper::BackendError; end

    attr_writer :vault

    def get(secret_name, _parameters = {})
      real_name = real_name(secret_name)

      result = case engine_type
               when "kv", "kv1"
                 vault.logical.read("#{engine}/#{real_name}")
               when "kv2"
                 vault.kv(engine).read(real_name)
               else
                 raise ClientError, "No support for secrets engine #{engine_type}"
               end

      raise VaultNotFoundError.new("No path found for ´#{engine}/#{real_name}´") unless result

      JSON.dump(result.data)
    end

    def list(secret_prefix = "", _parameters = {})
      real_prefix = real_name(secret_prefix)

      result = case engine_type
               when "kv", "kv1"
                 vault.logical.list("#{engine}/#{real_prefix}")
               when "kv2"
                 vault.kv(engine).list(real_prefix)
               else
                 raise ClientError, "No support for secrets engine #{engine_type}"
               end

      raise VaultNotFoundError.new("No subkeys found at `#{engine}/#{real_prefix}`") if result.nil?

      result
    end

    def raw_backend
      vault
    end

    private

    def real_name(secret_name)
      File.join(options[:prefix], secret_name)
    end

    def engine_type
      @options[:engine_type]
    end

    def engine
      @options[:engine]
    end

    def vault
      return @vault if @vault

      @vault = Vault::Client.new(backend_options)
    rescue Vault::HTTPClientError => err
      raise ClientError.new(err.message)
    end

    # Filter Safekeeper options so only valid `vault-ruby` options are left
    def backend_options
      raw_options = @options.dup

      raw_options[:address] = raw_options[:endpoint]
      raw_options.delete(:endpoing)

      # Removing Safekeeper-specific options
      %i{engine engine_type prefix}.each { |option| raw_options.delete(option) }

      raw_options
    end
  end
end
