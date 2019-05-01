# frozen_string_literal: true

require 'socket'

class TCPClient
  class Address
    attr_reader :to_s, :hostname, :addrinfo

    def initialize(addr)
      case addr
      when self.class
        init_from_selfclass(addr)
      when Integer
        init_from_addrinfo(Addrinfo.tcp(nil, addr))
      when Addrinfo
        init_from_addrinfo(addr)
      else
        init_from_string(addr)
      end
      @addrinfo.freeze
    end

    private

    def init_from_selfclass(address)
      @to_s = address.to_s
      @hostname = address.hostname
      @addrinfo = address.addrinfo
    end

    def init_from_addrinfo(addrinfo)
      @hostname, port = addrinfo.getnameinfo(Socket::NI_NUMERICSERV)
      @to_s = "#{@hostname}:#{port}"
      @addrinfo = addrinfo
    end

    def init_from_string(str)
      @hostname, port = from_string(str.to_s)
      return init_from_addrinfo(Addrinfo.tcp(nil, port)) unless @hostname
      @addrinfo = Addrinfo.tcp(@hostname, port)
      @to_s = as_str(@hostname, port)
    end

    def from_string(str)
      return [nil, str.to_i] unless idx = str.rindex(':')
      name = str[0, idx]
      name = name[1, name.size - 2] if name[0] == '[' && name[-1] == ']'
      [name, str[idx + 1, str.size - idx].to_i]
    end

    def as_str(hostname, port)
      return "[#{hostname}]:#{port}" if hostname.index(':') # IP6
      "#{hostname}:#{port}"
    end
  end
end
