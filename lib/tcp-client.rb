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
  def self.open(address, configuration = Configuration.default)
    client = new
    client.connect(Address.new(address), configuration)
    block_given? ? yield(client) : client
  ensure
    client&.close if block_given?
  end

  attr_reader :address

  def initialize
    @socket = @address = @deadline = @configuration = nil
  end

  def to_s
    @address&.to_s || ''
  end

  def connect(address, configuration, exception: nil)
    raise(NoOpenSSL) if configuration.ssl? && !defined?(SSLSocket)
    close
    @address = Address.new(address)
    @configuration = configuration.dup
    exception ||= configuration.connect_timeout_error
    @socket = TCPSocket.new(@address, @configuration, exception)
    @configuration.ssl? &&
      @socket = SSLSocket.new(@socket, @address, configuration, exception)
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
    previous_deadline = @deadline
    raise(NoBlockGiven) unless block_given?
    @deadline = Deadline.new(timeout)
    raise(InvalidDeadLine, timeout) unless @deadline.valid?
    yield(self)
  ensure
    @deadline = previous_deadline
  end

  def read(nbytes, timeout: nil, exception: nil)
    raise(NotConnected) if closed?
    timeout.nil? && @deadline and
      return read_with_deadline(nbytes, @deadline, exception)
    deadline = Deadline.new(timeout || @configuration.read_timeout)
    return @socket.read(nbytes) unless deadline.valid?
    read_with_deadline(nbytes, deadline, exception)
  end

  def write(*msg, timeout: nil, exception: nil)
    raise(NotConnected) if closed?
    timeout.nil? && @deadline and
      return write_with_deadline(msg, @deadline, exception)
    deadline = Deadline.new(timeout || @configuration.read_timeout)
    return @socket.write(*msg) unless deadline.valid?
    write_with_deadline(msg, deadline, exception)
  end

  def flush
    @socket.flush unless closed?
    self
  end

  private

  def read_with_deadline(nbytes, deadline, exception)
    exception ||= @configuration.read_timeout_error
    @socket.read_with_deadline(nbytes, deadline, exception)
  end

  def write_with_deadline(msg, deadline, exception)
    exception ||= @configuration.write_timeout_error
    msg.sum do |chunk|
      @socket.write_with_deadline(chunk.b, deadline, exception)
    end
  end
end
