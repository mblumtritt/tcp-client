# frozen_string_literal: true

require_relative 'configuration'

class TCPClient
  @default_configuration = Configuration.new

  class << self
    attr_reader :default_configuration

    def configure(options = {}, &block)
      @default_configuration = Configuration.create(options, &block)
    end
  end

  class Configuration
    def self.default
      TCPClient.default_configuration
    end
  end
end
