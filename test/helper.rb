# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/parallel'
require_relative '../lib/tcp-client'

# this pseudo-server never reads or writes anything
PseudoServer = TCPServer.new('localhost', 0)
Minitest.after_run { PseudoServer.close }

class Test < MiniTest::Test
  parallelize_me!
end

class Timing
  def initialize
    @start_time = nil
  end

  def started?
    @start_time != nil
  end

  def start
    @start_time = now
  end

  def elapsed
    now - @start_time
  end

  if defined?(Process::CLOCK_MONOTONIC)
    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  else
    def now
      ::Time.now
    end
  end
end
