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
      connect_to(
        address,
        ssl_params[:verify_mode] != OpenSSL::SSL::VERIFY_NONE,
        configuration.connect_timeout,
        exception
      )
    end

    private

    def create_context(ssl_params)
      context = OpenSSL::SSL::SSLContext.new
      context.set_params(ssl_params)
      context
    end

    def connect_to(address, check, timeout, exception)
      self.hostname = address.hostname
      deadline = Deadline.new(timeout)
      if deadline.valid?
        with_deadline(deadline, exception) do
          connect_nonblock(exception: false)
        end
      else
        connect
      end
      post_connection_check(address.hostname) if check
    end
  end

  private_constant(:SSLSocket)
end
