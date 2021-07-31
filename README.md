# TCPClient

A TCP client implementation with working timeout support.

## Description

This Gem implements a TCP client with (optional) SSL support. It is an easy to use, versatile configurable client that can correctly handle time limits. Unlike other implementations, this client respects predefined/configurable time limits for each method (`connect`, `read`, `write`). Deadlines for a sequence of read/write actions can also be monitored.

## Sample

```ruby
require 'tcp-client'

TCPClient.configure do |cfg|
  cfg.connect_timeout = 1 # limit connect time the server to 1 second
  cfg.ssl_params = { ssl_version: :TLSv1_2 } # use TLS 1.2
end

TCPClient.open('www.google.com:443') do |client|
  # next sequence should not last longer than 0.5 seconds
  client.with_deadline(0.5) do
    # simple HTTP get request
    pp client.write("GET / HTTP/1.1\r\nHost: www.google.com\r\n\r\n")

    # read "HTTP/1.1 " + 3 byte HTTP status code
    pp client.read(12)
  end
end
```

### Installation

Use [Bundler](http://gembundler.com/) to use TCPClient in your own project:

Add to your `Gemfile`:

```ruby
gem 'tcp-client'
```

and install it by running Bundler:

```bash
$ bundle
```

To install the gem globally use:

```bash
$ gem install tcp-client
```

After that you need only a single line of code in your project to have all tools on board:

```ruby
require 'tcp-client'
```
