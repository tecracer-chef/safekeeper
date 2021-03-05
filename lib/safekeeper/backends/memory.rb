require "safekeeper/plugins"

module Safekeeper::Backends
  class Memory < Safekeeper.plugin
    plugin_name "memory"

    class Data < Hash
      include Hashie::Extensions::MergeInitializer
      include Hashie::Extensions::IndifferentAccess
    end

    def initialize(options = {})
      options[:endpoint] = "memory://"

      super

      @data = Data.new
    end

    def get(secret_name, _parameters = {})
      delete(secret_name) if expired?(secret_name)

      @data.dig(secret_name, :contents)
    end

    # TODO: Expiry
    def list(secret_prefix = "", _parameters = {})
      subkeys = @data.keys.select do |full_key|
        full_key.start_with? "#{secret_prefix}/"
      end

      subkeys.map { |full_key| full_key.delete_prefix("#{secret_prefix}/") }
    end

    def put(secret_name, data, parameters = {})
      @data[secret_name] = {
        contents: data,
      }

      set_expiry(secret_name, Time.now + parameters[:ttl]) if parameters[:ttl]

      data
    end

    def delete(secret_name, _parameters = {})
      @data[secret_name] = nil
    end

    private

    def set_expiry(secret_name, expiry)
      return unless get(secret_name)

      @data[secret_name][:expiry] = expiry
    end

    def expiry(secret_name)
      @data.dig(secret_name, :expiry) || -1
    end

    def expired?(secret_name)
      expiry(secret_name) != -1 && expiry(secret_name) < Time.now
    end
  end
end
