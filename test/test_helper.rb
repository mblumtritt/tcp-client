require 'minitest/autorun'
require 'minitest/parallel'
require_relative '../lib/tcp-client'

$stdout.sync = $stderr.sync = true

class Test < Minitest::Test
  parallelize_me!
end

# this pseudo-server never reads or writes anything
DummyServer = TCPServer.new('localhost', 1234)
Minitest.after_run { DummyServer.close }
