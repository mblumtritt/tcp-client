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
# terminate before given time limits - or raise an exception.
#
# @example - request to Google.com and limit all network interactions to 1.5 seconds
#   TCPClient.with_deadline(1.5, 'www.google.com:443') do |client|
#     client.write("GET / HTTP/1.1\r\nHost: www.google.com\r\n\r\n")
#     client.read(12)
#   end
#   # => "HTTP/1.1 200"
#
#
class TCPClient
  #
  # Creates a new instance which is connected to the server on the given
  # address and uses the given or the {.default_configuration}.
  #
  # If an optional block is given, then the block's result is returned and the
  # connection will be closed when the block execution ends.
  # This can be used to create an ad-hoc connection which is garanteed to be
  # closed.
  #
  # If no block is giiven the connected client instance is returned.
  # This can be used as a shorthand to create & connect a client.
  #
  # @param address [Address, String, Addrinfo, Integer] the address to connect to, see {Address#initialize} for valid formats
  # @param configuration [Configuration] the {Configuration} to be used for this instance
  #
  # @yieldparam client [TCPClient] the connected client
  # @yieldreturn [Object] any result
  #
  # @return [Object, TCPClient] the block result or the connected client
  #
  # @see #connect
  #
  def self.open(address, configuration = nil)
    client = new
    client.connect(Address.new(address), configuration)
    block_given? ? yield(client) : client
  ensure
    client.close if block_given?
  end

  #
  # Yields a new instance which is connected to the server on the given
  # address and uses the given or the {.default_configuration}.
  # It ensures to close the connection when the block execution ends.
  # It also limits all {#read} and {#write} actions within the block to a given
  # time.
  #
  # This can be used to create an ad-hoc connection which is garanteed to be
  # closed and which read/write calls should not last longer than the timeout
  # limit.
  #
  # @param timeout [Numeric] maximum time in seconds for all {#read} and {#write} calls within the block
  # @param address [Address, String, Addrinfo, Integer] the address to connect to, see {Address#initialize} for valid formats
  # @param configuration [Configuration] the {Configuration} to be used for this instance
  #
  # @yieldparam client [TCPClient] the connected client
  # @yieldreturn [Object] any result
  #
  # @return [Object] the block result
  #
  # @see #with_deadline
  #
  def self.with_deadline(timeout, address, configuration = nil)
    client = nil
    raise(NoBlockGivenError) unless block_given?
    address = Address.new(address)
    client = new
    client.with_deadline(timeout) do
      yield(client.connect(address, configuration))
    end
  ensure
    client&.close
  end

  #
  # @return [Address] the address used for this client
  #
  attr_reader :address

  #
  # @return [Configuration] the configuration used by this client.
  #
  attr_reader :configuration

  #
  # @attribute [r] closed?
  # @return [Boolean] true when the connection is closed, false when connected
  #
  def closed?
    @socket.nil? || @socket.closed?
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
  # Establishes a new connection to a given address.
  #
  # It accepts a connection-specific configuration or uses the global {.default_configuration}. The {#configuration} used by this instance will
  # be a copy of the configuration used for this method call. This allows to
  # configure the behavior per connection.
  #
  # @param address [Address, String, Addrinfo, Integer] the address to connect to, see {Address#initialize} for valid formats
  # @param configuration [Configuration] the {Configuration} to be used for this instance
  # @param timeout [Numeric] maximum time in seconds to read; used to override the configuration's +connect_timeout+.
  # @param exception [Class] exception class to be used when the read timeout reached; used to override the configuration's +connect_timeout_error+.
  #
  # @return [self]
  #
  # @raise {NoOpenSSLError} if SSL should be used but OpenSSL is not avail
  #
  def connect(address, configuration = nil, timeout: nil, exception: nil)
    close if @socket
    @address = Address.new(address)
    @configuration = (configuration || Configuration.default).dup
    raise(NoOpenSSLError) if @configuration.ssl? && !defined?(SSLSocket)
    @socket = create_socket(timeout, exception)
    self
  end

  #
  # Close the current connection.
  #
  # @return [self]
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
  # Executes a block with a given overall timeout.
  #
  # When you like to ensure that a complete read/write communication sequence
  # with the server is finished before a given amount of time you can use this
  # method to define such a deadline.
  #
  # @example - ensure to send a welcome message and receive a 64 byte answer from server
  #   answer = client.with_deadline(2.5) do
  #     client.write('Helo')
  #     client.read(64)
  #   end
  #
  # @param timeout [Numeric] maximum time in seconds for all {#read} and {#write} calls within the block
  #
  # @yieldparam client [TCPClient] self
  #
  # @return [Object] result of the given block
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
  # Read the given nbytes or the next available buffer from server.
  #
  # @param nbytes [Integer] the number of bytes to read
  # @param timeout [Numeric] maximum time in seconds to read; used to override the configuration's +read_timeout+.
  # @param exception [Class] exception class to be used when the read timeout reached; used to override the configuration's +read_timeout_error+.
  #
  # @return [String] buffer read
  #
  # @raise [NotConnectedError] if {#connect} was not called before
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
  # Write the given messages to the server.
  #
  # @param messages [Array<String>] messages to write
  # @param timeout [Numeric] maximum time in seconds to read; used to override the configuration's +write_timeout+.
  # @param exception [Class] exception class to be used when the read timeout reached; used to override the configuration's +write_timeout_error+.
  #
  # @return [Integer] bytes written
  #
  # @raise [NotConnectedError] if {#connect} was not called before
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

  #
  # Flush all internal buffers (write all through).
  #
  # @return [self]
  #
  def flush
    stem_errors { @socket&.flush }
    self
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
    end.freeze
  private_constant(:NETWORK_ERRORS)
end
