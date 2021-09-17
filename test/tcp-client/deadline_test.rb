# frozen_string_literal: true

require_relative '../helper'

class DeadlineTest < Test
  Deadline = TCPClient.const_get(:Deadline)

  def test_validity
    assert(Deadline.new(1).valid?)
    assert(Deadline.new(0.0001).valid?)

    refute(Deadline.new(0).valid?)
    refute(Deadline.new(nil).valid?)
  end

  def test_remaining_time
    assert(Deadline.new(1).remaining_time > 0)

    assert_nil(Deadline.new(0).remaining_time)
    assert_nil(Deadline.new(nil).remaining_time)

    deadline = Deadline.new(0.2)
    sleep(0.2)
    assert_nil(deadline.remaining_time)
  end
end
