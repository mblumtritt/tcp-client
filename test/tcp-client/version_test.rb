# frozen_string_literal: true

require_relative '../helper'

class VersionTest < Test
  def test_format
    assert_match(/\d+\.\d+\.\d+/, TCPClient::VERSION)
  end
end
