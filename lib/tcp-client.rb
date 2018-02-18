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
      raise(self, format('client not connected - %s', which), caller(1))
    end
  end

  Timeout = Class.new(IOError)

  def self.open(addr, configuration = Configuration.new)
    addr = Address.new(addr)
    client = new
    client.connect(addr, configuration)
    return yield(client) if block_given?
    client, ret = nil, client
    ret
  ensure
    client.close if client
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
    @socket = SSLSocket.new(@socket, @address, configuration, Timeout) if configuration.ssl?
    @write_timeout = configuration.write_timeout
    @read_timeout = configuration.read_timeout
    self
  end

  def close
    socket, @socket = @socket, nil
    socket.close if socket
    self
  rescue IOError
    self
  end

  def closed?
    @socket.nil? || @socket.closed?
  end

  def read(nbytes, timeout: @read_timeout)
    closed? ? NotConnected.raise!(self) : @socket.read(nbytes, timeout: timeout, exception: Timeout)
  end

  def write(*msg, timeout: @write_timeout)
    closed? ? NotConnected.raise!(self)  : @socket.write(*msg, timeout: timeout, exception: Timeout)
  end
end
