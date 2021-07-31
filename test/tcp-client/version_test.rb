# frozen_string_literal: true

require_relative '../test_helper'

class VersionTest < MiniTest::Test
  parallelize_me!

  def test_format
    assert_match(/\d+\.\d+\.\d+/, TCPClient::VERSION)
  end
end
