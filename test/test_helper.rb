require 'minitest/autorun'
require 'minitest/parallel'
require_relative '../lib/tcp-client'

$stdout.sync = $stderr.sync = true

# this pseudo-server never reads or writes anything
DummyServer = TCPServer.new('localhost', 1234)
Minitest.after_run { DummyServer.close }
