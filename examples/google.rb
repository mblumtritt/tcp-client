# frozen_string_literal: true

require 'tcp-client'

# global configuration:
# - 0.5 seconds to connect the server
# - 0.25 seconds to write a single data junk
# - 0.25 seconds to read some bytes
TCPClient.configure do |cfg|
  cfg.connect_timeout = 0.5
  cfg.write_timeout = 0.25
  cfg.read_timeout = 0.25
end

# request to Google:
# - send a simple HTTP get request
# - read 12 byte: "HTTP/1.1 " + 3 byte HTTP status code
TCPClient.open('www.google.com:80') do |client|
  p client.write("GET / HTTP/1.1\r\nHost: www.google.com\r\n\r\n")
  p client.read(12)
end
