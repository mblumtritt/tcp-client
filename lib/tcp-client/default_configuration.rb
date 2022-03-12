# frozen_string_literal: true

require_relative 'configuration'

class TCPClient
  @default_configuration = Configuration.new

  class << self
    #
    # The default configuration.
    # This is used by default if no dedicated configuration was specified to
    # {.open} or {#connect}.
    #
    # @return [Configuration]
    #
    attr_reader :default_configuration

    #
    # Configure the {.default_configuration} which is used if no dedicated
    # configuration was specified to {.open} or {#connect}.
    #
    # @example
    #   TCPClient.configure do |cfg|
    #     cfg.buffered = false
    #     cfg.ssl_params = { min_version: :TLS1_2, max_version: :TLS1_3 }
    #   end
    #
    # @param options [Hash] see {Configuration#initialize} for details
    #
    # @yieldparam cfg {Configuration} the new configuration
    #
    # @return [Configuration] the new default configuration
    #
    def configure(options = {}, &block)
      @default_configuration = Configuration.create(options, &block)
    end
  end

  class Configuration
    class << self
      #
      # @!parse attr_reader :default
      # @return [Configuration] used by default if no dedicated configuration
      #   was specified
      #
      # @see TCPClient.open
      # @see TCPClient.with_deadline
      # @see TCPClient#connect
      #
      def default
        TCPClient.default_configuration
      end
    end
  end
end
