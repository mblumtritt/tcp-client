require_relative '../lib/tcp-client'

TCPClient.configure do |cfg|
  cfg.connect_timeout = 1 # second to connect the server
  cfg.ssl_params = { ssl_version: :TLSv1_2 } # use TLS 1.2
end

TCPClient.open('www.google.com:443') do |client|
  # query should not last longer than 0.5 seconds
  client.with_deadline(0.5) do
    # simple HTTP get request
    pp client.write("GET / HTTP/1.1\r\nHost: google.com\r\n\r\n")

    # read "HTTP/1.1 " + 3 byte HTTP status code
    pp client.read(12)
  end
end
