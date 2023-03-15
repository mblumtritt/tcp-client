# frozen_string_literal: true

require_relative 'errors'

class TCPClient
  #
  # A Configuration is used to configure the behavior of a {TCPClient} instance.
  #
  # It allows to specify the monitor timeout, how to handle exceptions, if SSL
  # should be used and to setup the underlying Socket.
  #
  class Configuration
    #
    # Shorthand to create a new configuration.
    #
    # @overload create()
    #   @example
    #     config = TCPClient::Configuration.create do |cfg|
    #       cfg.buffered = false
    #       cfg.ssl_params = { min_version: :TLS1_2, max_version: :TLS1_3 }
    #     end
    #
    #   @yieldparam configuration {Configuration}
    #
    # @overload create(options)
    #   @example
    #     config = TCPClient::Configuration.create(buffered: false)
    #
    #   @param options [{Symbol => Object}] see {#initialize} for details
    #
    # @return [Configuration] the initialized configuration
    #
    def self.create(options = nil)
      configuration = new(options)
      yield(configuration) if block_given?
      configuration
    end

    #
    # Initializes and optionally configures the instance with given options.
    #
    # @see #configure
    #
    def initialize(options = nil)
      @buffered = @keep_alive = @reverse_lookup = true
      self.timeout = @ssl_params = nil
      @connect_timeout_error = ConnectTimeoutError
      @read_timeout_error = ReadTimeoutError
      @write_timeout_error = WriteTimeoutError
      @normalize_network_errors = false
      configure(options) if options
    end

    # @!group Instance Attributes Socket Level

    #
    # Enables/disables use of Socket-level buffering
    #
    # @return [Boolean] whether the connection is allowed to use internal
    #   buffers (default) or not
    #
    attr_reader :buffered

    def buffered=(value)
      @buffered = value ? true : false
    end

    #
    # Enables/disables use of Socket-level keep alive handling.
    #
    # @return [Boolean] whether the connection is allowed to use keep alive
    #   signals (default) or not
    #
    attr_reader :keep_alive

    def keep_alive=(value)
      @keep_alive = value ? true : false
    end

    #
    # Enables/disables address lookup.
    #
    # @return [Boolean] whether the connection is allowed to lookup the address
    #   (default) or not
    #
    attr_reader :reverse_lookup

    def reverse_lookup=(value)
      @reverse_lookup = value ? true : false
    end

    #
    # @!parse attr_reader :ssl?
    # @return [Boolean] whether SSL is configured, see {#ssl_params}
    #
    def ssl?
      @ssl_params ? true : false
    end

    #
    # Parameters used to initialize a SSL context. SSL/TLS will only be used if
    # this attribute is not `nil`.
    #
    # @return [{Symbol => Object}] SSL parameters for the SSL context
    # @return [nil] if no SSL should be used (default)
    #
    attr_reader :ssl_params

    def ssl_params=(value)
      @ssl_params =
        if value.respond_to?(:to_hash)
          Hash[value.to_hash]
        elsif value.respond_to?(:to_h)
          value.nil? ? nil : Hash[value.to_h]
        else
          value ? {} : nil
        end
    end
    alias ssl= ssl_params=

    # @!endgroup

    # @!group Instance Attributes Timeout Monitoring

    #
    # The maximum time in seconds to establish a connection.
    #
    # @return [Numeric] maximum time in seconds
    # @return [nil] if the connect time should not be monitored (default)
    #
    # @see TCPClient#connect
    #
    attr_reader :connect_timeout

    def connect_timeout=(value)
      @connect_timeout = seconds(value)
    end

    #
    # The exception class which will be raised if {TCPClient#connect} can not
    # be finished in time.
    #
    # @return [Class<Exception>] exception class raised
    # @raise [NotAnExceptionError] if given argument is not an Exception class
    #
    attr_reader :connect_timeout_error

    def connect_timeout_error=(value)
      raise(NotAnExceptionError, value) unless exception_class?(value)
      @connect_timeout_error = value
    end

    #
    # The maximum time in seconds to read from a connection.
    #
    # @return [Numeric] maximum time in seconds
    # @return [nil] if the read time should not be monitored (default)
    #
    # @see TCPClient#read
    #
    attr_reader :read_timeout

    def read_timeout=(value)
      @read_timeout = seconds(value)
    end

    #
    # The exception class which will be raised if {TCPClient#read} can not be
    # finished in time.
    #
    # @return [Class<Exception>] exception class raised
    # @raise [NotAnExceptionError] if given argument is not an Exception class
    #
    attr_reader :read_timeout_error

    def read_timeout_error=(value)
      raise(NotAnExceptionError, value) unless exception_class?(value)
      @read_timeout_error = value
    end

    #
    # The maximum time in seconds to write to a connection.
    #
    # @return [Numeric] maximum time in seconds
    # @return [nil] if the write time should not be monitored (default)
    #
    # @see TCPClient#write
    #
    attr_reader :write_timeout

    def write_timeout=(value)
      @write_timeout = seconds(value)
    end

    #
    # The exception class which will be raised if {TCPClient#write} can not be
    # finished in time.
    #
    # @return [Class<Exception>] exception class raised
    # @raise [NotAnExceptionError] if given argument is not an Exception class
    #
    attr_reader :write_timeout_error

    def write_timeout_error=(value)
      raise(NotAnExceptionError, value) unless exception_class?(value)
      @write_timeout_error = value
    end

    #
    # @attribute [w] timeout
    # Shorthand to set maximum time in seconds for all timeout monitoring.
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
    # Shorthand to set the exception class which will by raised by any reached
    # timeout.
    #
    # @return [Class<Exception>] exception class raised
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

    # @!endgroup

    # @!group Other Instance Attributes

    #
    # Enables/disables if network exceptions should be raised as {NetworkError}.
    #
    # This allows to handle all network/socket related exceptions like
    # `SocketError`, `OpenSSL::SSL::SSLError`, `IOError`, etc. in a uniform
    # manner. If this option is set to true all these error cases are raised as
    # {NetworkError} and can be easily captured.
    #
    # @return [Boolean] whether all network exceptions should be raised as
    #   {NetworkError}, or not (default)
    #
    attr_reader :normalize_network_errors

    def normalize_network_errors=(value)
      @normalize_network_errors = value ? true : false
    end

    # @!endgroup

    #
    # @return [{Symbol => Object}] Hash containing all attributes
    #
    # @see #configure
    #
    def to_hash
      {
        buffered: @buffered,
        keep_alive: @keep_alive,
        reverse_lookup: @reverse_lookup,
        ssl_params: @ssl_params,
        connect_timeout: @connect_timeout,
        connect_timeout_error: @connect_timeout_error,
        read_timeout: @read_timeout,
        read_timeout_error: @read_timeout_error,
        write_timeout: @write_timeout,
        write_timeout_error: @write_timeout_error,
        normalize_network_errors: @normalize_network_errors
      }
    end

    #
    # @overload to_h
    # @overload to_h(&block)
    # @return [{Symbol => Object}] Hash containing all attributes
    #
    # @see #configure
    #
    def to_h(&block)
      block ? to_hash.to_h(&block) : to_hash
    end

    #
    # Configures the instance with given options Hash.
    #
    # @param options [{Symbol => Object}]
    # @option options [Boolean] :buffered, see {#buffered}
    # @option options [Boolean] :keep_alive, see {#keep_alive}
    # @option options [Boolean] :reverse_lookup, see {#reverse_lookup}
    # @option options [{Symbol => Object}] :ssl_params, see {#ssl_params}
    # @option options [Numeric] :connect_timeout, see {#connect_timeout}
    # @option options [Class<Exception>] :connect_timeout_error, see
    #   {#connect_timeout_error}
    # @option options [Numeric] :read_timeout, see {#read_timeout}
    # @option options [Class<Exception>] :read_timeout_error, see
    #   {#read_timeout_error}
    # @option options [Numeric] :write_timeout, see {#write_timeout}
    # @option options [Class<Exception>] :write_timeout_error, see
    #   {#write_timeout_error}
    # @option options [Boolean] :normalize_network_errors, see
    #   {#normalize_network_errors}
    #
    # @return [Configuration] self
    #
    def configure(options)
      options.each_pair { |attribute, value| set(attribute, value) }
      self
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
      to_hash == other.to_h
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
