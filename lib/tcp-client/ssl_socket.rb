begin
  require 'openssl'
rescue LoadError
  return
end

require_relative 'mixin/io_timeout'

class TCPClient
  class SSLSocket < ::OpenSSL::SSL::SSLSocket
    include IOTimeoutMixin

    def initialize(socket, address, configuration, exception)
      ssl_params = Hash[configuration.ssl_params]
      super(socket, create_context(ssl_params))
      connect_to(
        address,
        ssl_params[:verify_mode] != OpenSSL::SSL::VERIFY_NONE,
        configuration.connect_timeout,
        exception
      )
    end

    private

    def create_context(ssl_params)
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.set_params(ssl_params)
      ctx
    end

    def connect_to(address, check, timeout, exception)
      self.hostname = address.hostname
      timeout ? with_deadline(Time.now + timeout, exception){ connect_nonblock(exception: false) } : connect
      post_connection_check(address.hostname) if check
    end
  end

  private_constant :SSLSocket
end
