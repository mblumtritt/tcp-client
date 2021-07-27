require_relative '../lib/tcp-client'

TCPClient.configure(
  connect_timeout: 0.5, # seconds to connect the server
  write_timeout: 0.25, # seconds to write a single data junk
  read_timeout: 0.5 # seconds to read some bytes
)

# the following sequence is not allowed to last longer than 1.25 seconds:
#   0.5 seconds to connect
# + 0.25 seconds to write data
# + 0.5 seconds to read a response

TCPClient.open('www.google.com:80') do |client|
  # simple HTTP get request
  pp client.write("GET / HTTP/1.1\r\nHost: www.google.com\r\n\r\n")

  # read "HTTP/1.1 " + 3 byte HTTP status code
  pp client.read(12)
end
