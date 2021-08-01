# frozen_string_literal: true

class TCPClient
  class NoOpenSSL < RuntimeError
    def initialize
      super('OpenSSL is not available')
    end
  end

  class NoBlockGiven < ArgumentError
    def initialize
      super('no block given')
    end
  end

  class InvalidDeadLine < ArgumentError
    def initialize(timeout)
      super("invalid deadline - #{timeout}")
    end
  end

  class UnknownAttribute < ArgumentError
    def initialize(attribute)
      super("unknown attribute - #{attribute}")
    end
  end

  class NotAnException < TypeError
    def initialize(object)
      super("exception class required - #{object.inspect}")
    end
  end

  class NotConnected < IOError
    def initialize
      super('client not connected')
    end
  end

  class TimeoutError < IOError
    def initialize(message = nil)
      super(message || "unable to #{action} in time")
    end

    def action
      :process
    end
  end

  class ConnectTimeoutError < TimeoutError
    def action
      :connect
    end
  end

  class ReadTimeoutError < TimeoutError
    def action
      :read
    end
  end

  class WriteTimeoutError < TimeoutError
    def action
      :write
    end
  end

  Timeout = TimeoutError # backward compatibility
  deprecate_constant(:Timeout)
end
