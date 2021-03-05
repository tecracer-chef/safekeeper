require "safekeeper"

module Safekeeper
  module ChefHelpers

    # Connect to a secrets backend
    #
    # @example connect_safekeeper("vault")
    def connect_safekeeper(backend_name, data)
      # TODO: use ~/.chef/credentials of credential_type="safekeeper"

      __safekeeper_state["backends"][backend_name] = Safekeeper.create(backend, data)
    end

    # Get a secret by name
    #
    # @example get_secret("/serverdata")
    def get_secret(secret_name, backend_name = nil)
      __safekeeper_backend(backend_name).get(secret_name)
    end

    # List secrets matching a prefix/path
    #
    # @example list_secret_by_prefix("/servers/")
    def list_secrets_by_prefix(secret_prefix, backend_name = nil)
      __safekeeper_backend(backend_name).list(secret_prefix)
    end

    private

    def __safekeeper_backend(backend_name = nil)
      __safekeeper_state["backends"][backend_name]
    end

    def __safekeeper_state
      Chef::Node.run_state["safekeeper"] ||= {
        "backends" => {},
      }

      Chef::Node.run_state["safekeeper"]
    end
  end
end

::Chef::DSL::Recipe.send(:include, Safekeeper::ChefHelpers)
