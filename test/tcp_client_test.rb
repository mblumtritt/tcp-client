require_relative 'test_helper'

class TCPClientTest < Test
  def test_defaults
    subject = TCPClient.new
    assert(subject.closed?)
    assert_equal('', subject.to_s)
    assert_nil(subject.address)
    subject.close
    assert_raises(TCPClient::NotConnected) do
      subject.write('hello world!')
    end
    assert_raises(TCPClient::NotConnected) do
      subject.read(42)
    end
  end

  def create_nonconnected_client
    client = TCPClient.new
    client.connect('', TCPClient::Configuration.new)
  rescue Errno::EADDRNOTAVAIL
  ensure
    return client
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
    assert_raises(TCPClient::NotConnected) do
      subject.write('hello world!')
    end
    assert_raises(TCPClient::NotConnected) do
      subject.read(42)
    end
  end

  def with_dummy_server(port)
    # this server will never receive or send any data
    server = TCPServer.new('localhost', port)
    yield
  ensure
    server&.close
  end

  def test_connected_state
    with_dummy_server(1234) do
      TCPClient.open('localhost:1234') do |subject|
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
  end

  def check_read_write_timeout(addr, timeout)
    TCPClient.open(addr) do |subject|
      refute(subject.closed?)
      start_time = nil
      assert_raises(TCPClient::Timeout) do
        start_time = Time.now
        # send 1MB to avoid any TCP stack buffering
        subject.write('?' * (1024 * 1024), timeout: timeout)
      end
      assert_in_delta(timeout, Time.now - start_time, 0.02)
      assert_raises(TCPClient::Timeout) do
        start_time = Time.now
        subject.read(42, timeout: timeout)
      end
      assert_in_delta(timeout, Time.now - start_time, 0.02)
    end
  end

  def test_read_write_timeout
    with_dummy_server(1235) do
      [0.5, 1, 1.5].each do |timeout|
        check_read_write_timeout('localhost:1235', timeout)
      end
    end
  end

  def check_connect_timeout(addr, config)
    start_time = nil
    assert_raises(TCPClient::Timeout) do
      start_time = Time.now
      TCPClient.new.connect(addr, config)
    end
    assert_in_delta(config.connect_timeout, Time.now - start_time, 0.02)
  end

  def test_connect_ssl_timeout
    with_dummy_server(1236) do
      config = TCPClient::Configuration.new
      config.ssl = true
      [0.5, 1, 1.5].each do |timeout|
        config.timeout = timeout
        check_connect_timeout('localhost:1236', config)
      end
    end
  end
end
