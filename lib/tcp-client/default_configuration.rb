# frozen_string_literal: true

require_relative 'configuration'

class TCPClient
  @default_configuration = Configuration.new

  class << self
    #
    # @return [Configuration] used by default if no dedicated configuration was specified
    #
    attr_reader :default_configuration

    #
    # Configure the default configuration which is used if no dedicated
    # configuration was specified.
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
    #
    # @return [Configuration] used by default if no dedicated configuration was specified
    #
    def self.default
      TCPClient.default_configuration
    end
  end
end
