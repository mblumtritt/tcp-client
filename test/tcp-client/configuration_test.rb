require_relative '../test_helper'

class ConfigurationTest < MiniTest::Test
  parallelize_me!

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
    subject =
      TCPClient::Configuration.create do |cfg|
        cfg.buffered = cfg.keep_alive = cfg.reverse_lookup = false
        cfg.timeout = 42
        cfg.ssl = true
      end
    refute(subject.buffered)
    refute(subject.keep_alive)
    refute(subject.reverse_lookup)
    assert_same(42, subject.connect_timeout)
    assert_same(42, subject.read_timeout)
    assert_same(42, subject.write_timeout)
    assert(subject.ssl?)
  end

  def test_options
    subject =
      TCPClient::Configuration.new(
        buffered: false,
        keep_alive: false,
        reverse_lookup: false,
        connect_timeout: 1,
        read_timeout: 2,
        write_timeout: 3,
        ssl: true
      )
    refute(subject.buffered)
    refute(subject.keep_alive)
    refute(subject.reverse_lookup)
    assert_same(1, subject.connect_timeout)
    assert_same(2, subject.read_timeout)
    assert_same(3, subject.write_timeout)
    assert(subject.ssl?)
  end

  def test_invalid_option
    err =
      assert_raises(ArgumentError) do
        TCPClient::Configuration.new(unknown_attr: :argument)
      end
    assert_includes(err.message, 'attribute')
    assert_includes(err.message, 'unknown_attr')
  end

  def test_ssl_params
    subject = TCPClient::Configuration.new
    refute(subject.ssl?)
    assert_nil(subject.ssl_params)
    subject.ssl = true
    assert(subject.ssl?)
    assert_empty(subject.ssl_params)
    subject.ssl_params[:ssl_version] = :TLSv1_2
    subject.ssl = false
    assert_nil(subject.ssl_params)
  end

  def test_timeout_overwrite
    subject =
      TCPClient::Configuration.create do |cfg|
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

  def test_compare
    a = TCPClient::Configuration.new
    b = TCPClient::Configuration.new
    assert_equal(a, b)
    assert(a == b)
    assert(a === b)
  end
end
