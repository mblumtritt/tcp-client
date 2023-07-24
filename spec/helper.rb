# frozen_string_literal: true

require 'rspec/core'
require_relative '../lib/tcp-client'

$stdout.sync = $stderr.sync = $VERBOSE = true
RSpec.configure(&:disable_monkey_patching!)

SOCKET_ERRORS =
  [
    Errno::EADDRNOTAVAIL,
    Errno::ECONNABORTED,
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Errno::EHOSTUNREACH,
    Errno::EINVAL,
    Errno::ENETUNREACH,
    Errno::EPIPE,
    IOError,
    SocketError
  ].tap do |errors|
      errors << OpenSSL::SSL::SSLError if defined?(OpenSSL::SSL::SSLError)
    end
    .freeze
