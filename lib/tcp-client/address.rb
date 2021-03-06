# frozen_string_literal: true

require 'socket'

class TCPClient
  class Address
    attr_reader :hostname, :addrinfo

    def initialize(addr)
      case addr
      when self.class
        init_from_selfclass(addr)
      when Addrinfo
        init_from_addrinfo(addr)
      when Integer
        init_from_addrinfo(Addrinfo.tcp(nil, addr))
      else
        init_from_string(addr)
      end
      @addrinfo.freeze
    end

    def to_s
      return "[#{@hostname}]:#{@addrinfo.ip_port}" if @hostname.index(':') # IP6
      "#{@hostname}:#{@addrinfo.ip_port}"
    end

    def to_h
      { host: @hostname, port: @addrinfo.ip_port }
    end

    def ==(other)
      to_h == other.to_h
    end
    alias eql? ==

    def equal?(other)
      self.class == other.class && self == other
    end

    private

    def init_from_selfclass(address)
      @hostname = address.hostname
      @addrinfo = address.addrinfo
    end

    def init_from_addrinfo(addrinfo)
      @hostname, _port = addrinfo.getnameinfo(Socket::NI_NUMERICSERV)
      @addrinfo = addrinfo
    end

    def init_from_string(str)
      @hostname, port = from_string(str.to_s)
      return init_from_addrinfo(Addrinfo.tcp(nil, port)) unless @hostname
      @addrinfo = Addrinfo.tcp(@hostname, port)
    end

    def from_string(str)
      idx = str.rindex(':') or return nil, str.to_i
      name = str[0, idx]
      if name.start_with?('[') && name.end_with?(']')
        name = name[1, name.size - 2]
      end
      [name, str[idx + 1, str.size - idx].to_i]
    end
  end
end
