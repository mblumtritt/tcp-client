# frozen_string_literal: true

require 'socket'

class TCPClient
  #
  # The address used by a TCPClient.
  #
  # @note An {Address} does not resolve the required TCP information until it is
  #   needed.
  #
  #   This means that address resolution only occurs when an instance attribute
  #   is accessed or the address is frozen.
  #   To force the address resolution at a certain time, {#freeze} can be called.
  #
  class Address
    #
    # @attribute [r] addrinfo
    # @return [Addrinfo] the address info
    #
    def addrinfo
      freeze if @addrinfo.nil?
      @addrinfo
    end

    #
    # @attribute [r] host
    # @return [String] the host name
    #
    def host
      freeze if @host.nil?
      @host
    end
    alias hostname host

    #
    # @attribute [r] port
    # @return [Integer] the port number
    #
    def port
      addrinfo.ip_port
    end

    #
    # Initializes an address
    #
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
      @addr = addr
    end

    #
    # Convert `self` to a Hash containing host and port attribute.
    #
    # @return [Hash] host and port
    #
    def to_hash
      { host: host, port: port }
    end

    #
    # Convert `self` to a Hash containing host and port attribute.
    #
    # @overload to_h
    # @overload to_h(&block)
    # @return [Hash] host and port
    #
    def to_h(&block)
      block ? to_hash.to_h(&block) : to_hash
    end

    #
    # @return [String] text representation of self as "host:port"
    #
    def to_s
      host.index(':') ? "[#{host}]:#{port}" : "#{host}:#{port}"
    end

    #
    # Force the address resolution and prevents further modifications of itself.
    #
    # @return [Address] itself
    #
    def freeze
      return super if frozen?
      solve
      @addrinfo.freeze
      @host.freeze
      @addr = nil
      super
    end

    # @!visibility private
    def ==(other)
      to_hash == other.to_h
    end
    alias eql? ==

    # @!visibility private
    def equal?(other)
      self.class == other.class && self == other
    end

    private

    def solve
      case @addr
      when self.class
        from_self_class(@addr)
      when Addrinfo
        from_addrinfo(@addr)
      when Integer
        from_addrinfo(Addrinfo.tcp(nil, @addr))
      else
        from_string(@addr)
      end
    end

    def from_self_class(address)
      unless address.frozen?
        @addr = address.instance_variable_get(:@addr)
        return solve
      end
      @addrinfo = address.addrinfo
      @host = address.host
    end

    def from_addrinfo(addrinfo)
      @host = addrinfo.getnameinfo(Socket::NI_NUMERICSERV).first
      @addrinfo = addrinfo
    end

    def from_string(str)
      @host, port = host_n_port(str.to_s)
      return @addrinfo = Addrinfo.tcp(@host, port) if @host
      from_addrinfo(Addrinfo.tcp(nil, port))
    end

    def host_n_port(str)
      idx = str.rindex(':') or return nil, str.to_i
      name = str[0, idx].delete_prefix('[').delete_suffix(']')
      [name.empty? ? nil : name, str[idx + 1, str.size - idx].to_i]
    end
  end
end
