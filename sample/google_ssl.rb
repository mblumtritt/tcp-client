# frozen_string_literal: true

require_relative '../lib/tcp-client'

# create a configuration.
# - use TLS 1.2
# - don't use internal buffering
cfg =
  TCPClient::Configuration.create(
    buffered: false,
    ssl_params: {
      ssl_version: :TLSv1_2
    }
  )

# request to Google:
# - limit all interactions to 0.5 seconds
# - use the Configuration cfg
# - send a simple HTTP get request
# - read 12 byte: "HTTP/1.1 " + 3 byte HTTP status code
TCPClient.with_deadline(0.5, 'www.google.com:443', cfg) do |client|
  p client.write("GET / HTTP/1.1\r\nHost: www.google.com\r\n\r\n")
  p client.read(12)
end
