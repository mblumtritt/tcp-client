# frozen_string_literal: true

require_relative 'tcp-client/address'
require_relative 'tcp-client/tcp_socket'
require_relative 'tcp-client/ssl_socket'
require_relative 'tcp-client/configuration'
require_relative 'tcp-client/default_configuration'
require_relative 'tcp-client/version'

class TCPClient
  class NoOpenSSL < RuntimeError
    def self.raise!
      raise(self, 'OpenSSL is not avail', caller(1))
    end
  end

  class NotConnected < SocketError
    def self.raise!(reason)
      raise(self, "client not connected - #{reason}", caller(1))
    end
  end

  TimeoutError = Class.new(IOError)
  ConnectTimeoutError = Class.new(TimeoutError)
  ReadTimeoutError = Class.new(TimeoutError)
  WriteTimeoutError = Class.new(TimeoutError)

  Timeout = TimeoutError # backward compatibility
  deprecate_constant(:Timeout)

  def self.open(addr, configuration = Configuration.default)
    addr = Address.new(addr)
    client = new
    client.connect(addr, configuration)
    block_given? ? yield(client) : client
  ensure
    client&.close if block_given?
  end

  attr_reader :address

  def initialize
    @socket = @address = @write_timeout = @read_timeout = nil
    @deadline = nil
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
    socket, @socket = @socket, nil
    socket&.close
    self
  rescue IOError
    self
  ensure
    @deadline = nil
  end

  def closed?
    @socket.nil? || @socket.closed?
  end

  def with_deadline(timeout)
    raise('no block given') unless block_given?
    raise('deadline already used') if @deadline
    tm = timeout&.to_f
    raise(ArgumentError, "invalid deadline - #{timeout}") unless tm.positive?
    @deadline = Time.now + tm
    yield(self)
  ensure
    @deadline = nil
  end

  def read(nbytes, timeout: nil, exception: ReadTimeoutError)
    NotConnected.raise!(self) if closed?
    time = timeout || remaining_time(exception) || @read_timeout
    @socket.read(nbytes, timeout: time, exception: exception)
  end

  def write(*msg, timeout: nil, exception: WriteTimeoutError)
    NotConnected.raise!(self) if closed?
    time = timeout || remaining_time(exception) || @write_timeout
    @socket.write(*msg, timeout: time, exception: exception)
  end

  def flush
    @socket.flush unless closed?
    self
  end

  private

  def remaining_time(exception)
    return unless @deadline
    remaining_time = @deadline - Time.now
    0 < remaining_time ? remaining_time : raise(exception)
  end
end
