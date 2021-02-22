# frozen_string_literal: true

require_relative 'tcp-client/errors'
require_relative 'tcp-client/address'
require_relative 'tcp-client/tcp_socket'
require_relative 'tcp-client/ssl_socket'
require_relative 'tcp-client/configuration'
require_relative 'tcp-client/default_configuration'
require_relative 'tcp-client/version'

class TCPClient
  def self.open(addr, configuration = Configuration.default)
    client = new
    client.connect(Address.new(addr), configuration)
    block_given? ? yield(client) : client
  ensure
    client&.close if block_given?
  end

  attr_reader :address

  def initialize
    @socket = @address = @write_timeout = @read_timeout = @deadline = nil
  end

  def to_s
    @address ? @address.to_s : ''
  end

  def connect(addr, configuration, exception: ConnectTimeoutError)
    close
    NoOpenSSL.raise! if configuration.ssl? && !defined?(SSLSocket)
    @address = Address.new(addr)
    @socket = TCPSocket.new(@address, configuration, exception)
    configuration.ssl? &&
      @socket = SSLSocket.new(@socket, @address, configuration, exception)
    @write_timeout = configuration.write_timeout
    @read_timeout = configuration.read_timeout
    self
  end

  def close
    @socket&.close
    self
  rescue IOError
    self
  ensure
    @socket = @deadline = nil
  end

  def closed?
    @socket.nil? || @socket.closed?
  end

  def with_deadline(timeout)
    NoBlockGiven.raise! unless block_given?
    previous_deadline = @deadline
    tm = timeout&.to_f
    InvalidDeadLine.raise! unless tm&.positive?
    @deadline = Time.now + tm
    yield(self)
  ensure
    @deadline = previous_deadline
  end

  def read(nbytes, timeout: nil, exception: ReadTimeoutError)
    NotConnected.raise! if closed?
    if timeout.nil? && @deadline
      return @socket.read_with_deadline(nbytes, @deadline, exception)
    end
    timeout = (timeout || @read_timeout).to_f
    if timeout.positive?
      @socket.read_with_deadline(nbytes, Time.now + timeout, exception)
    else
      @socket.read(nbytes)
    end
  end

  def write(*msg, timeout: nil, exception: WriteTimeoutError)
    NotConnected.raise! if closed?
    if timeout.nil? && @deadline
      return @socket.write_with_deadline(msg.join.b, @deadline, exception)
    end
    timeout = (timeout || @read_timeout).to_f
    if timeout.positive?
      @socket.write_with_deadline(msg.join.b, Time.now + timeout, exception)
    else
      @socket.write(*msg)
    end
  end

  def flush
    @socket.flush unless closed?
    self
  end
end
