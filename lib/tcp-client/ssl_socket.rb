begin
  require 'openssl'
rescue LoadError
  return
end

require_relative 'mixin/io_timeout'

class TCPClient
  class SSLSocket < ::OpenSSL::SSL::SSLSocket
    include IOTimeoutMixin

    def initialize(socket, address, configuration)
      ssl_params = Hash[configuration.ssl_params]
      super(socket, create_context(ssl_params))
      connect_to(address, configuration.connect_timeout)
    end

    private

    def create_context(ssl_params)
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.set_params(ssl_params)
      ctx
    end

    def connect_to(address, timeout)
      self.hostname = address.hostname
      timeout ? with_deadline(Time.now + timeout){ connect_nonblock(exception: false) } : connect
      post_connection_check(address.hostname)
    end
  end

  private_constant :SSLSocket
end
