# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/parallel'
require_relative '../lib/tcp-client'

# this pseudo-server never reads or writes anything
PseudoServer = TCPServer.new('localhost', 0)
Minitest.after_run { PseudoServer.close }
