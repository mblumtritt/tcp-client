require_relative 'test_helper'

class TCPClientTest < MiniTest::Test
  parallelize_me!

  attr_reader :config

  def setup
    @config = TCPClient::Configuration.create(buffered: false)
  end

  def test_defaults
    subject = TCPClient.new
    assert(subject.closed?)
    assert_equal('', subject.to_s)
    assert_nil(subject.address)
    subject.close
    assert_raises(TCPClient::NotConnected) { subject.write('hello world!') }
    assert_raises(TCPClient::NotConnected) { subject.read(42) }
  end

  def create_nonconnected_client
    client = TCPClient.new
    client.connect('', config)
    client
  rescue Errno::EADDRNOTAVAIL
    client
  end

  def test_failed_state
    subject = create_nonconnected_client
    assert(subject.closed?)
    assert_equal('localhost:0', subject.to_s)
    refute_nil(subject.address)
    assert_equal('localhost:0', subject.address.to_s)
    assert_equal('localhost', subject.address.hostname)
    assert_instance_of(Addrinfo, subject.address.addrinfo)
    assert_same(0, subject.address.addrinfo.ip_port)
    assert_raises(TCPClient::NotConnected) { subject.write('hello world!') }
    assert_raises(TCPClient::NotConnected) { subject.read(42) }
  end

  def test_connected_state
    TCPClient.open('localhost:1234', config) do |subject|
      refute(subject.closed?)
      assert_equal('localhost:1234', subject.to_s)
      refute_nil(subject.address)
      address_when_opened = subject.address
      assert_equal('localhost:1234', subject.address.to_s)
      assert_equal('localhost', subject.address.hostname)
      assert_instance_of(Addrinfo, subject.address.addrinfo)
      assert_same(1234, subject.address.addrinfo.ip_port)

      subject.close
      assert(subject.closed?)
      assert_same(address_when_opened, subject.address)
    end
  end

  def check_read_timeout(timeout)
    TCPClient.open('localhost:1234', config) do |subject|
      refute(subject.closed?)
      start_time = nil
      assert_raises(TCPClient::ReadTimeoutError) do
        start_time = Time.now
        subject.read(42, timeout: timeout)
      end
      assert_in_delta(timeout, Time.now - start_time, 0.02)
    end
  end

  def test_read_timeout
    check_read_timeout(0.5)
    check_read_timeout(1)
    check_read_timeout(1.5)
  end

  def check_write_timeout(timeout)
    TCPClient.open('localhost:1234', config) do |subject|
      refute(subject.closed?)
      start_time = nil
      assert_raises(TCPClient::WriteTimeoutError) do
        start_time = Time.now

        # send 1MB to avoid any TCP stack buffering
        args = Array.new(2024, '?' * 1024)
        subject.write(*args, timeout: timeout)
      end
      assert_in_delta(timeout, Time.now - start_time, 0.02)
    end
  end

  def test_write_timeout
    check_write_timeout(0.1)
    check_write_timeout(0.25)
  end

  def check_connect_timeout(ssl_config)
    start_time = nil
    assert_raises(TCPClient::ConnectTimeoutError) do
      start_time = Time.now
      TCPClient.new.connect('localhost:1234', ssl_config)
    end
    assert_in_delta(ssl_config.connect_timeout, Time.now - start_time, 0.02)
  end

  def test_connect_ssl_timeout
    ssl_config = TCPClient::Configuration.new(ssl: true)

    ssl_config.connect_timeout = 0.5
    check_connect_timeout(ssl_config)

    ssl_config.connect_timeout = 1
    check_connect_timeout(ssl_config)

    ssl_config.connect_timeout = 1.5
    check_connect_timeout(ssl_config)
  end
end
