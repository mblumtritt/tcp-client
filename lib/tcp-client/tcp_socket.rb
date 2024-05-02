# frozen_string_literal: true

require 'socket'
require_relative 'deadline'
require_relative 'with_deadline'

class TCPClient
  class TCPSocket < ::Socket
    include WithDeadline

    def initialize(address, configuration, deadline, exception)
      super(address.addrinfo.ipv6? ? :INET6 : :INET, :STREAM)
      configure(configuration)
      connect_to(as_addr_in(address), deadline, exception)
    end

    private

    def as_addr_in(address)
      addrinfo = address.addrinfo
      ::Socket.pack_sockaddr_in(addrinfo.ip_port, addrinfo.ip_address)
    end

    def connect_to(addr, deadline, exception)
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
