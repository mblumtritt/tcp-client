# frozen_string_literal: true

require 'socket'
require_relative 'deadline'
require_relative 'mixin/io_with_deadline'

class TCPClient
  class TCPSocket < ::Socket
    include IOWithDeadlineMixin

    def initialize(address, configuration, exception)
      super(address.addrinfo.ipv6? ? :INET6 : :INET, :STREAM)
      configure(configuration)
      deadline = Deadline.new(configuration.connect_timeout)
      connect_to(address, deadline, exception)
    end

    private

    def connect_to(address, deadline, exception)
      addr =
        ::Socket.pack_sockaddr_in(
          address.addrinfo.ip_port,
          address.addrinfo.ip_address
        )
      return connect(addr) unless deadline.valid?
      with_deadline(deadline, exception) do
        connect_nonblock(addr, exception: false)
      end
    end

    def configure(configuration)
      unless configuration.buffered
        self.sync = true
        setsockopt(:TCP, :NODELAY, 1)
      end
      setsockopt(:SOCKET, :KEEPALIVE, configuration.keep_alive ? 1 : 0)
      self.do_not_reverse_lookup = configuration.reverse_lookup
    end
  end

  private_constant(:TCPSocket)
end
