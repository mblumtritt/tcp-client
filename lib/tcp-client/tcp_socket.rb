# frozen_string_literal: true

require 'socket'
require_relative 'deadline'
require_relative 'with_deadline'

class TCPClient
  class TCPSocket < ::Socket
    include WithDeadline

    def initialize(address, configuration, deadline)
      addrinfo = address.addrinfo
      super(addrinfo.ipv6? ? :INET6 : :INET, :STREAM)
      configure(configuration)
      connect_to(
        ::Socket.pack_sockaddr_in(addrinfo.ip_port, addrinfo.ip_address),
        deadline
      )
    end

    private

    def connect_to(addr, deadline)
      return connect(addr) unless deadline.valid?
      with_deadline(deadline) { connect_nonblock(addr, exception: false) }
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
