require 'socket'
require_relative 'mixin/io_timeout'

class TCPClient
  class TCPSocket < ::Socket
    include IOTimeoutMixin

    def initialize(address, configuration, exception)
      super(address.addrinfo.ipv6? ? :INET6 : :INET, :STREAM)
      configure(configuration)
      connect_to(address, configuration.connect_timeout, exception)
    end

    private

    def connect_to(address, timeout, exception)
      addr = ::Socket.pack_sockaddr_in(
        address.addrinfo.ip_port, address.addrinfo.ip_address
      )
      return connect(addr) unless timeout
      with_deadline(Time.now + timeout, exception) do
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

  private_constant :TCPSocket
end
