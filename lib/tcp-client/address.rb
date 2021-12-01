# frozen_string_literal: true

require 'socket'

class TCPClient
  #
  # The address used by a TCPClient
  #
  class Address
    #
    # @return [String] the host name
    #
    attr_reader :hostname

    #
    # @return [Addrinfo] the address info
    #
    attr_reader :addrinfo

    #
    # Initializes an address
    # @overload initialize(addr)
    #   The addr can be specified as
    #   - a valid named address containing the port like +my.host.test:80+
    #   - a valid TCPv4 address like +142.250.181.206:80+
    #   - a valid TCPv6 address like +[2001:16b8:5093:3500:ad77:abe6:eb88:47b6]:80+
    #
    #   @param addr [String] address string
    #
    # @overload initialize(address)
    #   Used to create a copy
    #
    #   @param address [Address]
    #
    # @overload initialize(addrinfo)
    #
    #   @param addrinfo [Addrinfo] containing the addressed host and port
    #
    # @overload initialize(port)
    #   Adresses the port on the local machine.
    #
    #   @param port [Integer] the addressed port
    #
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

    #
    # @return [String] text representation of self as "<host>:<port>"
    #
    def to_s
      return "[#{@hostname}]:#{@addrinfo.ip_port}" if @hostname.index(':') # IP6
      "#{@hostname}:#{@addrinfo.ip_port}"
    end

    #
    # @return [Hash] containing the host and port
    #
    def to_h
      { host: @hostname, port: @addrinfo.ip_port }
    end

    # @!visibility private
    def ==(other)
      to_h == other.to_h
    end
    alias eql? ==

    # @!visibility private
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
      name = str[0, idx].delete_prefix('[').delete_suffix(']')
      [name, str[idx + 1, str.size - idx].to_i]
    end
  end
end
