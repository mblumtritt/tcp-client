# frozen_string_literal: true

require_relative '../lib/tcp-client'

# create a configuration:
# - don't use internal buffering
# - use TLS 1.2 or TLS 1.3
cfg =
  TCPClient::Configuration.create(
    buffered: false,
    ssl_params: {
      min_version: :TLS1_2,
      max_version: :TLS1_3
    }
  )

# request to Google.com:
# - limit all network interactions to 1.5 seconds
# - use the Configuration cfg
# - send a simple HTTP get request
# - read the returned message and headers
response =
  TCPClient.with_deadline(1.5, 'www.google.com:443', cfg) do |client|
    client.write("GET / HTTP/1.1\r\nHost: www.google.com\r\n\r\n") #=> 40
    client.readline("\r\n\r\n") #=> see response
  end

puts(response)
