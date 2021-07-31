# frozen_string_literal: true

require_relative '../test_helper'

class Deadlineest < MiniTest::Test
  parallelize_me!

  def test_validity
    assert(TCPClient::Deadline.new(1).valid?)
    assert(TCPClient::Deadline.new(0.0001).valid?)

    refute(TCPClient::Deadline.new(0).valid?)
    refute(TCPClient::Deadline.new(nil).valid?)
  end

  def test_remaining_time
    assert(TCPClient::Deadline.new(1).remaining_time > 0)

    assert_nil(TCPClient::Deadline.new(0).remaining_time)
    assert_nil(TCPClient::Deadline.new(nil).remaining_time)

    deadline = TCPClient::Deadline.new(0.2)
    sleep(0.2)
    assert_nil(deadline.remaining_time)
  end
end
