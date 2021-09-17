# frozen_string_literal: true

require_relative '../helper'

class AddressTest < Test
  def test_create_from_integer
    subject = TCPClient::Address.new(42)
    assert_equal('localhost:42', subject.to_s)
    assert_equal('localhost', subject.hostname)
    assert(subject.addrinfo.ip?)
    assert(subject.addrinfo.ipv6?)
    assert_same(42, subject.addrinfo.ip_port)
  end

  def test_create_from_addrinfo
    addrinfo = Addrinfo.tcp('localhost', 42)
    subject = TCPClient::Address.new(addrinfo)
    assert_equal(addrinfo.getnameinfo[0], subject.hostname)
    assert_equal(addrinfo, subject.addrinfo)
  end

  def test_create_from_str
    subject = TCPClient::Address.new('localhost:42')
    assert_equal('localhost:42', subject.to_s)
    assert_equal('localhost', subject.hostname)
    assert(subject.addrinfo.ip?)
    assert(subject.addrinfo.ipv6?)
    assert_same(42, subject.addrinfo.ip_port)
  end

  def test_create_from_str_short
    subject = TCPClient::Address.new(':42')
    assert_equal(':42', subject.to_s)
    assert_empty(subject.hostname)
    assert_same(42, subject.addrinfo.ip_port)
    assert(subject.addrinfo.ip?)
    assert(subject.addrinfo.ipv4?)
  end

  def test_create_from_str_ip6
    subject = TCPClient::Address.new('[::1]:42')
    assert_equal('[::1]:42', subject.to_s)
    assert_equal('::1', subject.hostname)
    assert_same(42, subject.addrinfo.ip_port)
    assert(subject.addrinfo.ip?)
    assert(subject.addrinfo.ipv6?)
  end

  def test_create_from_empty_str
    subject = TCPClient::Address.new('')
    assert_equal('localhost:0', subject.to_s)
    assert_equal('localhost', subject.hostname)
    assert_same(0, subject.addrinfo.ip_port)
    assert(subject.addrinfo.ip?)
    assert(subject.addrinfo.ipv6?)
  end

  def test_compare
    a = TCPClient::Address.new('localhost:42')
    b = TCPClient::Address.new('localhost:42')
    assert_equal(a, b)
    assert(a == b)
    assert(a === b)
  end
end
