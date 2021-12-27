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
    #
    #     - a valid named address containing the port like "my.host.test:80"
    #     - a valid TCPv4 address like "142.250.181.206:80"
    #     - a valid TCPv6 address like
    #       "[2001:16b8:5093:3500:ad77:abe6:eb88:47b6]:80"
    #
    #   @example create an Address instance with a host name and port
    #     Address.new('www.google.com:80')
    #
    #   @param addr [String] address containing host and port name
    #
    #
    # @overload initialize(addrinfo)
    #
    #   @example create an Address with an Addrinfo
    #     Address.new(Addrinfo.tcp('www.google.com', 'http'))
    #
    #   @param addrinfo [Addrinfo] containing the addressed host and port
    #
    # @overload initialize(port)
    #   Addresses the port on the local machine.
    #
    #   @example create an Address for localhost on port 80
    #     Address.new(80)
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
    # @attribute [r] port
    # @return [Integer] the port number
    #
    def port
      @addrinfo.ip_port
    end

    #
    # @return [String] text representation of self as "host:port"
    #
    def to_s
      hostname.index(':') ? "[#{hostname}]:#{port}" : "#{hostname}:#{port}"
    end

    #
    # Convert `self` to a Hash containing host and port attribute.
    #
    # @return [Hash] host and port
    #
    def to_h
      { host: hostname, port: port }
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
      @hostname = addrinfo.getnameinfo(Socket::NI_NUMERICSERV).first
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
      [name.empty? ? nil : name, str[idx + 1, str.size - idx].to_i]
    end
  end
end
