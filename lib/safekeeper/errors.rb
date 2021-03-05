module Safekeeper
  # Base exception for any exception explicitly raised by the Train library.
  class Error < ::StandardError
    attr_reader :reason

    def initialize(message = "", reason = :not_provided)
      super(message)
      @reason = reason
    end
  end

  # Base exception class for all exceptions that are caused by user input
  # errors.
  class UserError < Error; end

  # We could not load a plugin, because of a user error
  class PluginLoadError < UserError
    attr_accessor :backend_name
  end

  # Base exception class for all exceptions that are caused by incorrect use
  # of an API.
  class ClientError < Error; end

  # Base exception class for all exceptions that are caused by other failures
  # in the backend layer.
  class BackendError < Error; end
end
