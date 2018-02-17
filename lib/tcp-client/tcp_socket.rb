require 'socket'
require_relative 'mixin/io_timeout'

class TCPClient
  class TCPSocket < ::Socket
    include IOTimeoutMixin

    def initialize(address, configuration)
      super(address.addrinfo.ipv6? ? :INET6 : :INET, :STREAM)
      configure(configuration)
      connect_to(address, configuration.connect_timeout)
    end

    private

    def connect_to(address, timeout)
      addr = ::Socket.pack_sockaddr_in(address.addrinfo.ip_port, address.addrinfo.ip_address)
      timeout ? with_deadline(Time.now + timeout){ connect_nonblock(addr, exception: false) } : connect(addr)
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

  private_constant :TCPSocket
end
