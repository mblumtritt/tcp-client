# frozen_string_literal: true

require_relative 'errors'

class TCPClient
  #
  # A Configuration is used to configure the behavior of a {TCPClient} instance.
  #
  # It allows to specify to monitor timeout, how to handle exceptions, if SSL
  # should be used and to setup the underlying Socket.
  #
  class Configuration
    #
    # @overload create(options)
    #   Shorthand to create a new configuration with given options.
    #
    #   @example
    #     config = TCPClient::Configuration.create(buffered: false)
    #
    #   @param options [Hash] see {#initialize} for details
    #
    #   @return [Configuration] the initialized configuration
    #
    # @overload create(&block)
    #   Shorthand to initialize a new configuration.
    #
    #   @example
    #     config = TCPClient::Configuration.create do |cfg|
    #       cfg.buffered = false
    #       cfg.ssl_params = { min_version: :TLS1_2, max_version: :TLS1_3 }
    #     end
    #
    #   @yieldparam cfg {Configuration}
    #
    #   @return [Configuration] the initialized configuration
    #
    def self.create(options = {})
      cfg = new(options)
      yield(cfg) if block_given?
      cfg
    end

    #
    # Intializes the instance with given options.
    #
    # @param options [Hash]
    # @option options [Boolean] :buffered, see {#buffered}
    # @option options [Boolean] :keep_alive, see {#keep_alive}
    # @option options [Boolean] :reverse_lookup, see {#reverse_lookup}
    # @option options [Boolean] :normalize_network_errors, see
    #   {#normalize_network_errors}
    # @option options [Numeric] :connect_timeout, see {#connect_timeout}
    # @option options [Exception] :connect_timeout_error, see
    #   {#connect_timeout_error}
    # @option options [Numeric] :read_timeout, see {#read_timeout}
    # @option options [Exception] :read_timeout_error, see {#read_timeout_error}
    # @option options [Numeric] :write_timeout, see {#write_timeout}
    # @option options [Exception] :write_timeout_error, see
    #   {#write_timeout_error}
    # @option options [Hash<Symbol, Object>] :ssl_params, see {#ssl_params}
    #
    def initialize(options = {})
      @buffered = @keep_alive = @reverse_lookup = true
      self.timeout = @ssl_params = nil
      @connect_timeout_error = ConnectTimeoutError
      @read_timeout_error = ReadTimeoutError
      @write_timeout_error = WriteTimeoutError
      @normalize_network_errors = false
      options.each_pair { |attribute, value| set(attribute, value) }
    end

    #
    # Enables/disables use of Socket-level buffers.
    #
    # @return [true] if the connection is allowed to use internal buffers
    #   (default)
    # @return [false] if buffering is not allowed
    #
    attr_reader :buffered

    def buffered=(value)
      @buffered = value ? true : false
    end

    #
    # Enables/disables use of Socket-level keep alive handling.
    #
    # @return [true] if the connection is allowed to use keep alive signals
    #   (default)
    # @return [false] if the connection should not check keep alive
    #
    attr_reader :keep_alive

    def keep_alive=(value)
      @keep_alive = value ? true : false
    end

    #
    # Enables/disables address lookup.
    #
    # @return [true] if the connection is allowed to lookup the address
    #   (default)
    # @return [false] if the address lookup is not required
    #
    attr_reader :reverse_lookup

    def reverse_lookup=(value)
      @reverse_lookup = value ? true : false
    end

    #
    # Enables/disables if network exceptions should be raised as {NetworkError}.
    #
    # This allows to handle all network/socket related exceptions like
    # `SocketError`, `OpenSSL::SSL::SSLError`, `IOError`, etc. in a uniform
    # manner. If this option is set to true all these error cases are raised as
    # {NetworkError} and can be easily captured.
    #
    # @return [true] if all network exceptions should be raised as
    #   {NetworkError}
    # @return [false] if socket/system errors should not be normalzed (default)
    #
    attr_reader :normalize_network_errors

    def normalize_network_errors=(value)
      @normalize_network_errors = value ? true : false
    end

    #
    # @attribute [w] timeout
    # Shorthand to set timeout value for connect, read and write at once or to
    # disable any timeout monitoring
    #
    # @return [Numeric] maximum time in seconds for any action
    # @return [nil] if all timeout monitoring should be disabled (default)
    #
    # @see #connect_timeout
    # @see #read_timeout
    # @see #write_timeout
    #
    def timeout=(value)
      @connect_timeout = @write_timeout = @read_timeout = seconds(value)
    end

    #
    # @attribute [w] timeout_error
    # Shorthand to configure exception class raised when connect, read or write
    # exceeded the configured timeout
    #
    # @return [Class] exception class raised
    #
    # @raise [NotAnExceptionError] if given argument is not an Exception class
    #
    # @see #connect_timeout_error
    # @see #read_timeout_error
    # @see #write_timeout_error
    #
    def timeout_error=(value)
      raise(NotAnExceptionError, value) unless exception_class?(value)
      @connect_timeout_error =
        @read_timeout_error = @write_timeout_error = value
    end

    #
    # Configures maximum time in seconds to establish a connection.
    #
    # @return [Numeric] maximum time in seconds to establish a connection
    # @return [nil] if the connect time should not be checked (default)
    #
    attr_reader :connect_timeout

    def connect_timeout=(value)
      @connect_timeout = seconds(value)
    end

    #
    # @return [Class] exception class raised if a {TCPClient#connect} timed out
    # @raise [NotAnExceptionError] if given argument is not an Exception class
    #
    attr_reader :connect_timeout_error

    def connect_timeout_error=(value)
      raise(NotAnExceptionError, value) unless exception_class?(value)
      @connect_timeout_error = value
    end

    #
    # Configures maximum time in seconds to finish a {TCPClient#read}.
    #
    # @return [Numeric] maximum time in seconds to finish a {TCPClient#read}
    #   request
    # @return [nil] if the read time should not be checked (default)
    #
    attr_reader :read_timeout

    def read_timeout=(value)
      @read_timeout = seconds(value)
    end

    #
    # @return [Class] exception class raised if a {TCPClient#read} timed out
    # @raise [NotAnExceptionError] if given argument is not an Exception class
    #
    attr_reader :read_timeout_error

    def read_timeout_error=(value)
      raise(NotAnExceptionError, value) unless exception_class?(value)
      @read_timeout_error = value
    end

    #
    # Configures maximum time in seconds to finish a {TCPClient#write}.
    #
    # @return [Numeric] maximum time in seconds to finish a {TCPClient#write}
    #   request
    # @return [nil] if the write time should not be checked (default)
    #
    attr_reader :write_timeout

    def write_timeout=(value)
      @write_timeout = seconds(value)
    end

    #
    # @return [Class] exception class raised if a {TCPClient#write} timed out
    # @raise [NotAnExceptionError] if given argument is not an Exception class
    #
    attr_reader :write_timeout_error

    def write_timeout_error=(value)
      raise(NotAnExceptionError, value) unless exception_class?(value)
      @write_timeout_error = value
    end

    #
    # @attribute ssl?
    # @return [Boolean] wheter SSL is configured, see {#ssl_params}
    #
    def ssl?
      @ssl_params ? true : false
    end

    #
    # Configures the SSL parameters used to initialize a SSL context.
    #
    # @return [Hash<Symbol, Object>] SSL parameters for the SSL context
    # @return [nil] if no SSL should be used (default)
    #
    attr_reader :ssl_params

    def ssl_params=(value)
      @ssl_params =
        if value.respond_to?(:to_hash)
          Hash[value.to_hash]
        elsif value.respond_to?(:to_h)
          Hash[value.to_h]
        else
          value ? {} : nil
        end
    end
    alias ssl= ssl_params=

    #
    # @return [Hash] configuration as a Hash
    #
    def to_h
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

    # @!visibility private
    def freeze
      @ssl_params.freeze
      super
    end

    # @!visibility private
    def initialize_copy(_org)
      super
      @ssl_params = Hash[@ssl_params] if @ssl_params
      self
    end

    # @!visibility private
    def ==(other)
      to_h == other.to_h
    end
    alias eql? ==

    # @!visibility private
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
