# frozen_string_literal: true

require_relative 'tcp-client/errors'
require_relative 'tcp-client/address'
require_relative 'tcp-client/deadline'
require_relative 'tcp-client/tcp_socket'
require_relative 'tcp-client/ssl_socket'
require_relative 'tcp-client/configuration'
require_relative 'tcp-client/default_configuration'
require_relative 'tcp-client/version'

class TCPClient
  def self.open(address, configuration = nil)
    client = new
    client.connect(Address.new(address), configuration)
    block_given? ? yield(client) : client
  ensure
    client.close if block_given?
  end

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

  attr_reader :address, :configuration

  def to_s
    @address&.to_s || ''
  end

  def connect(address, configuration = nil, timeout: nil, exception: nil)
    close if @socket
    raise(NoOpenSSLError) if configuration.ssl? && !defined?(SSLSocket)
    @address = Address.new(address)
    @configuration = (configuration || Configuration.default).dup
    @socket = create_socket(timeout, exception)
    self
  end

  def close
    @socket&.close
    self
  rescue *NETWORK_ERRORS
    self
  ensure
    @socket = @deadline = nil
  end

  def closed?
    @socket.nil? || @socket.closed?
  end

  def with_deadline(timeout)
    previous_deadline = @deadline
    raise(NoBlockGivenError) unless block_given?
    @deadline = Deadline.new(timeout)
    raise(InvalidDeadLineError, timeout) unless @deadline.valid?
    yield(self)
  ensure
    @deadline = previous_deadline
  end

  def read(nbytes = nil, timeout: nil, exception: nil)
    raise(NotConnectedError) if closed?
    deadline = create_deadline(timeout, configuration.read_timeout)
    return stem_errors { @socket.read(nbytes) } unless deadline.valid?
    exception ||= configuration.read_timeout_error
    stem_errors(exception) do
      @socket.read_with_deadline(nbytes, deadline, exception)
    end
  end

  def write(*msg, timeout: nil, exception: nil)
    raise(NotConnectedError) if closed?
    deadline = create_deadline(timeout, configuration.write_timeout)
    return stem_errors { @socket.write(*msg) } unless deadline.valid?
    exception ||= configuration.write_timeout_error
    stem_errors(exception) do
      msg.sum do |chunk|
        @socket.write_with_deadline(chunk.b, deadline, exception)
      end
    end
  end

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
end
