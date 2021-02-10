require_relative '../lib/tcp-client'

configuration =
  TCPClient::Configuration.create do |cfg|
    cfg.connect_timeout = 0.5 # seconds to connect the server
    cfg.write_timeout = 0.25 # seconds to write a single data junk
    cfg.read_timeout = 0.5 # seconds to read some bytes
  end

# the following request sequence is not allowed to last longer than 1.25 seconds:
# 0.5 seconds to connect
# + 0.25 seconds to write data
# + 0.5 seconds to read a response
TCPClient.open('www.google.com:80', configuration) do |client|
  pp client.write("GET / HTTP/1.1\r\nHost: google.com\r\n\r\n") # simple HTTP get request
  pp client.read(12) # "HTTP/1.1 " + 3 byte HTTP status code
end
