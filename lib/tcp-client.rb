# frozen_string_literal: true

require_relative 'tcp-client/errors'
require_relative 'tcp-client/address'
require_relative 'tcp-client/deadline'
require_relative 'tcp-client/tcp_socket'
require_relative 'tcp-client/ssl_socket'
require_relative 'tcp-client/configuration'
require_relative 'tcp-client/default_configuration'
require_relative 'tcp-client/version'

#
# Client class to communicate with a server via TCP w/o SSL.
#
# All connect/read/write actions can be monitored to ensure that all actions
# terminate before given time limit - or raise an exception.
#
# @example request to Google.com and limit network interactions to 1.5 seconds
#   # create a configuration to use at least TLS 1.2
#   cfg = TCPClient::Configuration.create(ssl_params: {min_version: :TLS1_2})
#
#   response =
#     TCPClient.with_deadline(1.5, 'www.google.com:443', cfg) do |client|
#       client.write("GET / HTTP/1.1\r\nHost: www.google.com\r\n\r\n") #=> 40
#       client.readline("\r\n\r\n") #=> see response
#     end
#   # response contains the returned message and header
#
class TCPClient
  #
  # Creates a new instance which is connected to the server on the given
  # `address`.
  #
  # If no `configuration` is given, the {.default_configuration} will be used.
  #
  # @overload open(address, configuration = nil)
  #   @yieldparam client [TCPClient] the connected client
  #
  #   @return [Object] the block result
  #
  # @overload open(address, configuration = nil)
  #   @return [TCPClient] the connected client
  #
  # If an optional block is given, then the block's result is returned and the
  # connection will be closed when the block execution ends.
  # This can be used to create an ad-hoc connection which is guaranteed to be
  # closed.
  #
  # If no block is given the connected client instance is returned.
  # This can be used as a shorthand to create & connect a client.
  #
  # @param address [Address, String, Addrinfo, Integer] the target address see
  #   {Address#initialize} for valid formats
  # @param configuration [Configuration] the {Configuration} to be used for
  #   the new instance
  #
  # @see #connect
  #
  def self.open(address, configuration = nil)
    client = new
    client.connect(address, configuration)
    block_given? ? yield(client) : client
  ensure
    client.close if block_given?
  end

  #
  # Yields an instance which is connected to the server on the given
  # `address`. It limits all {#read} and {#write} actions within the block to
  # the given time.
  #
  # It ensures to close the connection when the block execution ends and returns
  # the block's result.
  #
  # This can be used to create an ad-hoc connection which is guaranteed to be
  # closed and which {#read}/{#write} call sequence should not last longer than
  # the `timeout` seconds.
  #
  # If no `configuration` is given, the {.default_configuration} will be used.
  #
  # @param timeout [Numeric] maximum time in seconds for all {#read} and
  #   {#write} calls within the block
  # @param address [Address, String, Addrinfo, Integer] the target address see
  #   {Address#initialize} for valid formats
  # @param configuration [Configuration] the {Configuration} to be used for
  #   the instance
  #
  # @yieldparam client [TCPClient] the connected client
  #
  # @return [Object] the block's result
  #
  # @see #with_deadline
  #
  def self.with_deadline(timeout, address, configuration = nil)
    client = nil
    raise(NoBlockGivenError) unless block_given?
    client = new
    client.with_deadline(timeout) do
      yield(client.connect(address, configuration))
    end
  ensure
    client&.close
  end

  #
  # @return [Address] the address used by this client instance
  #
  attr_reader :address

  #
  # @return [Configuration] the configuration used by this client instance
  #
  attr_reader :configuration

  #
  # @!parse attr_reader :closed?
  # @return [Boolean] whether the connection is closed
  #
  def closed?
    @socket.nil? || @socket.closed?
  end

  #
  # Close the current connection if connected.
  #
  # @return [TCPClient] itself
  #
  def close
    @socket&.close
    self
  rescue *NETWORK_ERRORS
    self
  ensure
    @socket = @deadline = nil
  end

  #
  # Establishes a new connection to a server on given `address`.
  #
  # It accepts a connection-specific `configuration` or uses the
  # {.default_configuration}.
  #
  # The optional `timeout` and `exception` parameters allow to override the
  # `connect_timeout` and `connect_timeout_error` values.
  #
  # @param address [Address, String, Addrinfo, Integer] the target address, see
  #   {Address#initialize} for valid formats
  # @param configuration [Configuration] the {Configuration} to be used for
  #   this instance
  # @param timeout [Numeric] maximum time in seconds to connect
  # @param exception [Class<Exception>] exception class to be used when the
  #   connect timeout reached
  #
  # @return [TCPClient] itself
  #
  # @raise [NoOpenSSLError] if SSL should be used but OpenSSL is not avail
  #
  # @see NetworkError
  #
  def connect(address, configuration = nil, timeout: nil, exception: nil)
    close if @socket
    @configuration = (configuration || Configuration.default).dup
    raise(NoOpenSSLError) if @configuration.ssl? && !defined?(SSLSocket)
    @address = stem_errors { Address.new(address) }
    @socket = create_socket(timeout, exception)
    self
  end

  #
  # Flushes all internal buffers (write all buffered data).
  #
  # @return [TCPClient] itself
  #
  def flush
    stem_errors { @socket&.flush }
    self
  end

  #
  # Read the given `nbytes` or the next available buffer from server.
  #
  # The optional `timeout` and `exception` parameters allow to override the
  # `read_timeout` and `read_timeout_error` values of the used {#configuration}.
  #
  # @param nbytes [Integer] the number of bytes to read
  # @param timeout [Numeric] maximum time in seconds to read
  # @param exception [Class<Exception>] exception class to be used when the
  #   read timeout reached
  #
  # @return [String] the read buffer
  #
  # @raise [NotConnectedError] if {#connect} was not called before
  #
  # @see NetworkError
  #
  def read(nbytes = nil, timeout: nil, exception: nil)
    raise(NotConnectedError) if closed?
    deadline = create_deadline(timeout, configuration.read_timeout)
    return stem_errors { @socket.read(nbytes) } unless deadline.valid?
    exception ||= configuration.read_timeout_error
    stem_errors(exception) do
      @socket.read_with_deadline(nbytes, deadline, exception)
    end
  end

  #
  # Reads the next line from server.
  #
  # The standard record separator is used as `separator`.
  #
  # The optional `timeout` and `exception` parameters allow to override the
  # `read_timeout` and `read_timeout_error` values of the used {#configuration}.
  #
  # @param separator [String] the line separator to be used
  # @param timeout [Numeric] maximum time in seconds to read
  # @param exception [Class<Exception>] exception class to be used when the
  #   read timeout reached
  #
  # @return [String] the read line
  #
  # @raise [NotConnectedError] if {#connect} was not called before
  #
  # @see NetworkError
  #
  def readline(separator = $/, chomp: false, timeout: nil, exception: nil)
    raise(NotConnectedError) if closed?
    deadline = create_deadline(timeout, configuration.read_timeout)
    unless deadline.valid?
      return stem_errors { @socket.readline(separator, chomp: chomp) }
    end
    exception ||= configuration.read_timeout_error
    line =
      stem_errors(exception) do
        @socket.read_to_with_deadline(separator, deadline, exception)
      end
    chomp ? line.chomp : line
  end

  #
  # @return [String] the currently used address as text.
  #
  # @see Address#to_s
  #
  def to_s
    @address&.to_s || ''
  end

  #
  # Executes a block with a given overall time limit.
  #
  # When you like to ensure that a complete {#read}/{#write} communication
  # sequence with the server is finished before a given amount of time you use
  # this method.
  #
  # @example ensure to send SMTP welcome message and receive a 4 byte answer
  #   answer = client.with_deadline(2.5) do
  #     client.write('HELO')
  #     client.read(4)
  #   end
  #   # answer is EHLO when server speaks fluent SMPT
  #
  # @param timeout [Numeric] maximum time in seconds for all {#read} and
  #   {#write} calls within the block
  #
  # @yieldparam client [TCPClient] self
  #
  # @return [Object] the block's result
  #
  # @raise [NoBlockGivenError] if the block is missing
  #
  def with_deadline(timeout)
    previous_deadline = @deadline
    raise(NoBlockGivenError) unless block_given?
    @deadline = Deadline.new(timeout)
    raise(InvalidDeadLineError, timeout) unless @deadline.valid?
    yield(self)
  ensure
    @deadline = previous_deadline
  end

  #
  # Writes the given `messages` to the server.
  #
  # The optional `timeout` and `exception` parameters allow to override the
  # `write_timeout` and `write_timeout_error` values of the used
  # {#configuration}.
  #
  # @param messages [Array<String>] one or more messages to write
  # @param timeout [Numeric] maximum time in seconds to write
  # @param exception [Class<Exception>] exception class to be used when the
  #   write timeout reached
  #
  # @return [Integer] bytes written
  #
  # @raise [NotConnectedError] if {#connect} was not called before
  #
  # @see NetworkError
  #
  def write(*messages, timeout: nil, exception: nil)
    raise(NotConnectedError) if closed?
    deadline = create_deadline(timeout, configuration.write_timeout)
    return stem_errors { @socket.write(*messages) } unless deadline.valid?
    exception ||= configuration.write_timeout_error
    stem_errors(exception) do
      messages.sum do |chunk|
        @socket.write_with_deadline(chunk.b, deadline, exception)
      end
    end
  end

  private

  def create_deadline(timeout, default)
    timeout.nil? && @deadline ? @deadline : Deadline.new(timeout || default)
  end

  def create_socket(timeout, exception)
    deadline = create_deadline(timeout, configuration.connect_timeout)
    exception ||= configuration.connect_timeout_error
    stem_errors(exception) do
      @socket = TCPSocket.new(address, configuration, deadline, exception)
      return @socket unless configuration.ssl?
      SSLSocket.new(@socket, address, configuration, deadline, exception)
    end
  end

  def stem_errors(except = nil)
    yield
  rescue *NETWORK_ERRORS => e
    raise unless configuration.normalize_network_errors
    (except && e.is_a?(except)) ? raise : raise(NetworkError, e)
  end

  NETWORK_ERRORS =
    [
      Errno::EADDRNOTAVAIL,
      Errno::ECONNABORTED,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EHOSTUNREACH,
      Errno::EINVAL,
      Errno::ENETUNREACH,
      Errno::EPIPE,
      IOError,
      SocketError
    ].tap do |errors|
        errors << ::OpenSSL::SSL::SSLError if defined?(::OpenSSL::SSL::SSLError)
      end
      .freeze
  private_constant(:NETWORK_ERRORS)
end
