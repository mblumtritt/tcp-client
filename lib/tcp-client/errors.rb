# frozen_string_literal: true

require 'socket'

class TCPClient
  class NoOpenSSL < RuntimeError
    def self.raise!
      raise(self, 'OpenSSL is not avail', caller(1))
    end
  end

  class NoBlockGiven < RuntimeError
    def self.raise!
      raise(self, 'no block given', caller(1))
    end
  end

  class InvalidDeadLine < ArgumentError
    def self.raise!(timeout)
      raise(self, "invalid deadline - #{timeout}", caller(1))
    end
  end

  class UnknownAttribute < ArgumentError
    def self.raise!(attribute)
      raise(self, "unknown attribute - #{attribute}", caller(1))
    end
  end

  class NotAnException < TypeError
    def self.raise!(object)
      raise(self, "not a valid exception class - #{object.inspect}", caller(1))
    end
  end

  class NotConnected < SocketError
    def self.raise!
      raise(self, 'client not connected', caller(1))
    end
  end

  TimeoutError = Class.new(IOError)
  ConnectTimeoutError = Class.new(TimeoutError)
  ReadTimeoutError = Class.new(TimeoutError)
  WriteTimeoutError = Class.new(TimeoutError)

  Timeout = TimeoutError # backward compatibility
  deprecate_constant(:Timeout)
end
