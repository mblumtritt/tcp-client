# frozen_string_literal: true

begin
  require 'openssl'
rescue LoadError
  return
end

require_relative 'deadline'
require_relative 'mixin/io_with_deadline'

class TCPClient
  class SSLSocket < ::OpenSSL::SSL::SSLSocket
    include IOWithDeadlineMixin

    def initialize(socket, address, configuration, deadline, exception)
      ssl_params = Hash[configuration.ssl_params]
      super(socket, create_context(ssl_params))
      self.sync_close = true
      self.hostname = address.hostname
      check_new_session if @new_session
      deadline.valid? ? connect_with_deadline(deadline, exception) : connect
      post_connection_check(address.hostname) if should_verify?(ssl_params)
    end

    private

    def create_context(ssl_params)
      @new_session = nil
      ::OpenSSL::SSL::SSLContext.new.tap do |ctx|
        ctx.set_params(ssl_params)
        ctx.session_cache_mode = CONTEXT_CACHE_MODE
        ctx.session_new_cb = proc { @new_session = _2 }
      end
    end

    def check_new_session
      time = @new_session.time.to_f + @new_session.timeout
      if Process.clock_gettime(Process::CLOCK_REALTIME) < time
        self.session = @new_session
      end
    end

    def connect_with_deadline(deadline, exception)
      with_deadline(deadline, exception) { connect_nonblock(exception: false) }
    end

    def should_verify?(ssl_params)
      ssl_params[:verify_mode] != ::OpenSSL::SSL::VERIFY_NONE &&
        context.verify_hostname
    end

    CONTEXT_CACHE_MODE =
      ::OpenSSL::SSL::SSLContext::SESSION_CACHE_CLIENT |
        ::OpenSSL::SSL::SSLContext::SESSION_CACHE_NO_INTERNAL_STORE
  end

  private_constant(:SSLSocket)
end
