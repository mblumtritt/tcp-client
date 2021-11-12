# frozen_string_literal: true

require_relative 'errors'

class TCPClient
  class Configuration
    def self.create(options = {})
      ret = new(options)
      yield(ret) if block_given?
      ret
    end

    attr_reader :buffered,
                :keep_alive,
                :reverse_lookup,
                :normalize_network_errors,
                :connect_timeout,
                :read_timeout,
                :write_timeout,
                :connect_timeout_error,
                :read_timeout_error,
                :write_timeout_error
    attr_accessor :ssl_params

    def initialize(options = {})
      @buffered = @keep_alive = @reverse_lookup = true
      self.timeout = @ssl_params = nil
      @connect_timeout_error = ConnectTimeoutError
      @read_timeout_error = ReadTimeoutError
      @write_timeout_error = WriteTimeoutError
      @normalize_network_errors = false
      options.each_pair { |attribute, value| set(attribute, value) }
    end

    def freeze
      @ssl_params.freeze
      super
    end

    def initialize_copy(_org)
      super
      @ssl_params = Hash[@ssl_params] if @ssl_params
      self
    end

    def ssl?
      @ssl_params ? true : false
    end

    def ssl=(value)
      @ssl_params =
        if value.respond_to?(:to_hash)
          Hash[value.to_hash]
        else
          value ? {} : nil
        end
    end

    def buffered=(value)
      @buffered = value ? true : false
    end

    def keep_alive=(value)
      @keep_alive = value ? true : false
    end

    def reverse_lookup=(value)
      @reverse_lookup = value ? true : false
    end

    def normalize_network_errors=(value)
      @normalize_network_errors = value ? true : false
    end

    def timeout=(seconds)
      @connect_timeout = @write_timeout = @read_timeout = seconds(seconds)
    end

    def connect_timeout=(seconds)
      @connect_timeout = seconds(seconds)
    end

    def read_timeout=(seconds)
      @read_timeout = seconds(seconds)
    end

    def write_timeout=(seconds)
      @write_timeout = seconds(seconds)
    end

    def timeout_error=(exception)
      raise(NotAnExceptionError, exception) unless exception_class?(exception)
      @connect_timeout_error =
        @read_timeout_error = @write_timeout_error = exception
    end

    def connect_timeout_error=(exception)
      raise(NotAnExceptionError, exception) unless exception_class?(exception)
      @connect_timeout_error = exception
    end

    def read_timeout_error=(exception)
      raise(NotAnExceptionError, exception) unless exception_class?(exception)
      @read_timeout_error = exception
    end

    def write_timeout_error=(exception)
      raise(NotAnExceptionError, exception) unless exception_class?(exception)
      @write_timeout_error = exception
    end

    def to_hash
      {
        buffered: @buffered,
        keep_alive: @keep_alive,
        reverse_lookup: @reverse_lookup,
        connect_timeout: @connect_timeout,
        connect_timeout_error: @connect_timeout_error,
        read_timeout: @read_timeout,
        read_timeout_error: @read_timeout_error,
        write_timeout: @write_timeout,
        write_timeout_error: @write_timeout_error,
        ssl_params: @ssl_params
      }
    end

    def to_h(*args)
      args.empty? ? to_hash : to_hash.slice(*args)
    end

    def ==(other)
      to_hash == other.to_hash
    end
    alias eql? ==

    def equal?(other)
      self.class == other.class && self == other
    end

    private

    def exception_class?(value)
      value.is_a?(Class) && value < Exception
    end

    def set(attribute, value)
      public_send("#{attribute}=", value)
    rescue NoMethodError
      raise(UnknownAttributeError, attribute)
    end

    def seconds(value)
      value&.to_f&.positive? ? value : nil
    end
  end
end
