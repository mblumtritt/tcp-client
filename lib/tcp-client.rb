# frozen_string_literal: true

require_relative 'tcp-client/address'
require_relative 'tcp-client/tcp_socket'
require_relative 'tcp-client/ssl_socket'
require_relative 'tcp-client/configuration'
require_relative 'tcp-client/version'

class TCPClient
  class NoOpenSSL < RuntimeError
    def self.raise!
      raise(self, 'OpenSSL is not avail', caller(1))
    end
  end

  class NotConnected < SocketError
    def self.raise!(which)
      raise(self, "client not connected - #{which}", caller(1))
    end
  end

  Timeout = Class.new(IOError)

  def self.open(addr, configuration = Configuration.new)
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
  end

  def to_s
    @address ? @address.to_s : ''
  end

  def connect(addr, configuration)
    close
    NoOpenSSL.raise! if configuration.ssl? && !defined?(SSLSocket)
    @address = Address.new(addr)
    @socket = TCPSocket.new(@address, configuration, Timeout)
    configuration.ssl? && @socket = SSLSocket.new(
      @socket, @address, configuration, Timeout
    )
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
  end

  def closed?
    @socket.nil? || @socket.closed?
  end

  def read(nbytes, timeout: @read_timeout)
    NotConnected.raise!(self) if closed?
    @socket.read(nbytes, timeout: timeout, exception: Timeout)
  end

  def write(*msg, timeout: @write_timeout)
    NotConnected.raise!(self) if closed?
    @socket.write(*msg, timeout: timeout, exception: Timeout)
  end

  def flush
    @socket.flush unless closed?
    self
  end
end
