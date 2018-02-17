require_relative '../test_helper'

class VersionTest < Test
  def test_format
    assert_match(/\d+\.\d+\.\d+/, TCPClient::VERSION)
  end
end
