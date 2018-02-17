require_relative '../test_helper'

class ConfigurationTest < Test
  def test_defaults
    subject = TCPClient::Configuration.new
    assert(subject.buffered)
    assert(subject.keep_alive)
    assert(subject.reverse_lookup)
    refute(subject.ssl?)
    assert_nil(subject.connect_timeout)
    assert_nil(subject.read_timeout)
    assert_nil(subject.write_timeout)
  end

  def test_configure
    subject = TCPClient::Configuration.create do |cfg|
      cfg.buffered = cfg.keep_alive = cfg.reverse_lookup = false
      cfg.timeout = 42
      cfg.ssl_params = {}
    end
    refute(subject.buffered)
    refute(subject.keep_alive)
    refute(subject.reverse_lookup)
    assert_same(42, subject.connect_timeout)
    assert_same(42, subject.read_timeout)
    assert_same(42, subject.write_timeout)
    assert(subject.ssl?)
  end

  def test_timeout_overwrite
    subject = TCPClient::Configuration.create do |cfg|
      cfg.connect_timeout = 1
      cfg.read_timeout = 2
      cfg.write_timeout = 3
    end
    assert_same(1, subject.connect_timeout)
    assert_same(2, subject.read_timeout)
    assert_same(3, subject.write_timeout)

    subject.timeout = 42
    assert_same(42, subject.connect_timeout)
    assert_same(42, subject.read_timeout)
    assert_same(42, subject.write_timeout)
  end
end
