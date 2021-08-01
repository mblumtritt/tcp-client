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

    def initialize(socket, address, configuration, exception)
      ssl_params = Hash[configuration.ssl_params]
      super(socket, create_context(ssl_params))
      self.sync_close = true
      self.hostname = address.hostname
      deadline = Deadline.new(configuration.connect_timeout)
      deadline.valid? ? connect_with_deadline(deadline, exception) : connect
      post_connection_check(address.hostname) if should_verify?(ssl_params)
    end

    private

    def create_context(ssl_params)
      context = OpenSSL::SSL::SSLContext.new
      context.set_params(ssl_params)
      context
    end

    def connect_with_deadline(deadline, exception)
      with_deadline(deadline, exception) { connect_nonblock(exception: false) }
    end

    def should_verify?(ssl_params)
      ssl_params[:verify_mode] != OpenSSL::SSL::VERIFY_NONE
    end
  end

  private_constant(:SSLSocket)
end
