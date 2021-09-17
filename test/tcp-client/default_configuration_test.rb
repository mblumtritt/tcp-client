require_relative '../helper'

class DefauktConfigurationTest < MiniTest::Test
  def test_default
    subject = TCPClient.configure # reset to defaults

    assert_same(
      TCPClient.default_configuration,
      TCPClient::Configuration.default
    )
    assert(subject.buffered)
    assert(subject.keep_alive)
    assert(subject.reverse_lookup)
    refute(subject.ssl?)
    assert_nil(subject.connect_timeout)
    assert_nil(subject.read_timeout)
    assert_nil(subject.write_timeout)
  end

  def test_configure_options
    TCPClient.configure(
      buffered: false,
      keep_alive: false,
      reverse_lookup: false,
      ssl: true,
      connect_timeout: 1,
      read_timeout: 2,
      write_timeout: 3
    )
    subject = TCPClient.default_configuration
    refute(subject.buffered)
    refute(subject.keep_alive)
    refute(subject.reverse_lookup)
    assert(subject.ssl?)
    assert_same(1, subject.connect_timeout)
    assert_same(2, subject.read_timeout)
    assert_same(3, subject.write_timeout)
  end

  def test_configure_block
    TCPClient.configure do |cfg|
      cfg.buffered = false
      cfg.keep_alive = false
      cfg.reverse_lookup = false
      cfg.ssl = true
      cfg.connect_timeout = 1
      cfg.read_timeout = 2
      cfg.write_timeout = 3
    end
    subject = TCPClient.default_configuration
    refute(subject.buffered)
    refute(subject.keep_alive)
    refute(subject.reverse_lookup)
    assert(subject.ssl?)
    assert_same(1, subject.connect_timeout)
    assert_same(2, subject.read_timeout)
    assert_same(3, subject.write_timeout)
  end
end
