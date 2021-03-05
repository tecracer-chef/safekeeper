module Safekeeper
  # Path for core backend plugins
  BACKEND_PLUGIN_PATH = File.join(__dir__, "backends").freeze

  # Prefix for Gems providing Safekeeper backends
  BACKEND_PLUGIN_PREFIX = "safekeeper-backend-".freeze
end
