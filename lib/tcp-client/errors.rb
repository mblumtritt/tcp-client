# frozen_string_literal: true

class TCPClient
  class NoOpenSSLError < RuntimeError
    def initialize
      super('OpenSSL is not available')
    end
  end

  class NoBlockGivenError < ArgumentError
    def initialize
      super('no block given')
    end
  end

  class InvalidDeadLineError < ArgumentError
    def initialize(timeout)
      super("invalid deadline - #{timeout}")
    end
  end

  class UnknownAttributeError < ArgumentError
    def initialize(attribute)
      super("unknown attribute - #{attribute}")
    end
  end

  class NotAnExceptionError < TypeError
    def initialize(object)
      super("exception class required - #{object.inspect}")
    end
  end

  class NotConnectedError < IOError
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

  NoOpenSSL = NoOpenSSLError
  NoBlockGiven = NoBlockGivenError
  InvalidDeadLine = InvalidDeadLineError
  UnknownAttribute = UnknownAttributeError
  NotAnException = NotAnExceptionError
  NotConnected = NotConnectedError
  deprecate_constant(
    :NoOpenSSL,
    :NoBlockGiven,
    :InvalidDeadLine,
    :UnknownAttribute,
    :NotAnException,
    :NotConnected
  )
end
