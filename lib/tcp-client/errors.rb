# frozen_string_literal: true

class TCPClient
  #
  # Raised when a SSL connection should be established but the OpenSSL gem is
  # not available.
  #
  class NoOpenSSLError < RuntimeError
    def initialize = super('OpenSSL is not available')
  end

  #
  # Raised when a method requires a callback block but no such block is
  # specified.
  #
  class NoBlockGivenError < ArgumentError
    def initialize = super('no block given')
  end

  #
  # Raised when an invalid timeout value was specified.
  #
  class InvalidDeadLineError < ArgumentError
    #
    # @param timeout [Object] the invalid value
    #
    def initialize(timeout) = super("invalid deadline - #{timeout}")
  end

  #
  # Raised by {Configuration} when an undefined attribute should  be set.
  #
  class UnknownAttributeError < ArgumentError
    #
    # @param attribute [Object] the undefined attribute
    #
    def initialize(attribute) = super("unknown attribute - #{attribute}")
  end

  #
  # Raised when a given timeout exception parameter is not an exception class.
  #
  class NotAnExceptionError < TypeError
    #
    # @param object [Object] the invalid object
    #
    def initialize(object)
      super("exception class required - #{object.inspect}")
    end
  end

  #
  # Base exception class for all network related errors.
  #
  # Will be raised for any system level network error when
  # {Configuration.normalize_network_errors} is configured.
  #
  # You should catch this exception class when you like to handle any relevant
  # {TCPClient} error.
  #
  class NetworkError < StandardError
  end

  #
  # Raised when a {TCPClient} instance should read/write from/to the network
  # but is not connected.
  #
  class NotConnectedError < NetworkError
    def initialize = super('client not connected')
  end

  #
  # Base exception class for a detected timeout.
  #
  # You should catch this exception class when you like to handle any timeout
  # error.
  #
  class TimeoutError < NetworkError
    #
    # Initializes the instance with an optional message.
    #
    # The message will be generated from {#action} when not specified.
    #
    # @overload initialize
    # @overload initialize(message)
    #
    # @param message [#to_s] the error message
    #
    def initialize(message = nil)
      super(message || "unable to #{action} in time")
    end

    #
    # @attribute [r] action
    # @return [Symbol] the action which timed out
    #
    def action = :process
  end

  #
  # Raised by default whenever a {TCPClient.connect} timed out.
  #
  class ConnectTimeoutError < TimeoutError
    #
    # @attribute [r] action
    # @return [Symbol] the action which timed out: `:connect`
    #
    def action = :connect
  end

  #
  # Raised by default whenever a {TCPClient#read} timed out.
  #
  class ReadTimeoutError < TimeoutError
    #
    # @attribute [r] action
    # @return [Symbol] the action which timed out: :read`
    #
    def action = :read
  end

  #
  # Raised by default whenever a {TCPClient#write} timed out.
  #
  class WriteTimeoutError < TimeoutError
    #
    # @attribute [r] action
    # @return [Symbol] the action which timed out: `:write`
    #
    def action = :write
  end
end
