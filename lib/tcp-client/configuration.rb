class TCPClient
  class Configuration
    def self.create(options = {})
      ret = new(options)
      yield(ret) if block_given?
      ret
    end

    attr_reader :buffered, :keep_alive, :reverse_lookup
    attr_accessor :ssl_params

    def initialize(options = {})
      @buffered = @keep_alive = @reverse_lookup = true
      self.timeout = @ssl_params = nil
      options.each_pair(&method(:set))
    end

    def ssl?
      @ssl_params ? true : false
    end

    def ssl=(yn)
      return @ssl_params = nil unless yn
      return @ssl_params = yn if Hash === yn
      @ssl_params ||= {}
    end

    def buffered=(yn)
      @buffered = yn ? true : false
    end

    def keep_alive=(yn)
      @keep_alive = yn ? true : false
    end

    def reverse_lookup=(yn)
      @reverse_lookup = yn ? true : false
    end

    def timeout=(seconds)
      @timeout = seconds(seconds)
      @connect_timeout = @write_timeout = @read_timeout = nil
    end

    def connect_timeout
      @connect_timeout || @timeout
    end

    def connect_timeout=(seconds)
      @connect_timeout = seconds(seconds)
    end

    def write_timeout
      @write_timeout || @timeout
    end

    def write_timeout=(seconds)
      @write_timeout = seconds(seconds)
    end

    def read_timeout
      @read_timeout || @timeout
    end

    def read_timeout=(seconds)
      @read_timeout = seconds(seconds)
    end

    private

    def set(attribute, value)
      public_send("#{attribute}=", value)
    rescue NoMethodError
      raise(ArgumentError, "unknown attribute - #{attribute}")
    end

    def seconds(value)
      value&.positive? ? value : nil
    end
  end
end
