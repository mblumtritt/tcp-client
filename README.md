# TCPClient

A TCP client implementation with working timeout support.

## Description

This Gem implements a TCP client with (optional) SSL support. It is an easy to use, versatile configurable client that can correctly handle time limits. Unlike other implementations, this client respects predefined/configurable time limits for each method (`connect`, `read`, `write`). Deadlines for a sequence of read/write actions can also be monitored.

## Sample

```ruby
require 'tcp-client'

# create a configuration:
# - don't use internal buffering
# - use TLS 1.2 or TLS 1.3
cfg = TCPClient::Configuration.create(
  buffered: false,
  ssl_params: {min_version: :TLS1_2, max_version: :TLS1_3}
)

# request to Google.com:
# - limit all network interactions to 1.5 seconds
# - use the Configuration cfg
# - send a simple HTTP get request
# - read 12 byte: "HTTP/1.1 " + 3 byte HTTP status code
TCPClient.with_deadline(1.5, 'www.google.com:443', cfg) do |client|
  client.write("GET / HTTP/1.1\r\nHost: www.google.com\r\n\r\n") # >= 40
  client.read(12) # => "HTTP/1.1 200"
end
```

## Installation

Use [Bundler](http://gembundler.com/) to use TCPClient in your own project:

Add to your `Gemfile`:

```ruby
gem 'tcp-client'
```

and install it by running Bundler:

```bash
bundle
```

To install the gem globally use:

```bash
gem install tcp-client
```

After that you need only a single line of code in your project to have all tools on board:

```ruby
require 'tcp-client'
```
