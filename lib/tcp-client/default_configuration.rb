require_relative 'configuration'

class TCPClient
  @default_configuration = Configuration.new

  class << self
    attr_reader :default_configuration

    def configure(options = {})
      cfg = Configuration.new(options)
      yield(cfg) if block_given?
      @default_configuration = cfg
    end
  end

  class Configuration
    def self.default
      TCPClient.default_configuration
    end
  end
end
