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
    client.close if block_given?
  end

  def self.with_deadline(
    timeout,
    address,
    configuration = Configuration.default
  )
    client = nil
    raise(NoBlockGiven) unless block_given?
    address = Address.new(address)
    client = new
    client.with_deadline(timeout) do
      yield(client.connect(address, configuration))
    end
  ensure
    client&.close
  end

  attr_reader :address, :configuration

  def initialize
    @socket = @address = @deadline = @configuration = nil
  end

  def to_s
    @address&.to_s || ''
  end

  def connect(address, configuration, timeout: nil, exception: nil)
    close if @socket
    raise(NoOpenSSL) if configuration.ssl? && !defined?(SSLSocket)
    @address = Address.new(address)
    @configuration = configuration.dup.freeze
    @socket = create_socket(timeout, exception)
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

  def read(nbytes = nil, timeout: nil, exception: nil)
    raise(NotConnected) if closed?
    deadline = create_deadline(timeout, configuration.read_timeout)
    return @socket.read(nbytes) unless deadline.valid?
    exception ||= configuration.read_timeout_error
    @socket.read_with_deadline(nbytes, deadline, exception)
  end

  def write(*msg, timeout: nil, exception: nil)
    raise(NotConnected) if closed?
    deadline = create_deadline(timeout, configuration.write_timeout)
    return @socket.write(*msg) unless deadline.valid?
    exception ||= configuration.write_timeout_error
    msg.sum do |chunk|
      @socket.write_with_deadline(chunk.b, deadline, exception)
    end
  end

  def flush
    @socket&.flush
    self
  end

  private

  def create_deadline(timeout, default)
    timeout.nil? && @deadline ? @deadline : Deadline.new(timeout || default)
  end

  def create_socket(timeout, exception)
    deadline = create_deadline(timeout, configuration.connect_timeout)
    exception ||= configuration.connect_timeout_error
    @socket = TCPSocket.new(address, configuration, deadline, exception)
    return @socket unless configuration.ssl?
    SSLSocket.new(@socket, address, configuration, deadline, exception)
  end
end
