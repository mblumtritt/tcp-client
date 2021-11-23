# frozen_string_literal: true

require_relative '../helper'

RSpec.describe TCPClient::Address do
  describe '.new' do
    context 'when called with an Integer parameter' do
      subject(:address) { TCPClient::Address.new(42) }

      it 'points to the given port on localhost' do
        expect(address.hostname).to eq 'localhost'
        expect(address.to_s).to eq 'localhost:42'
        expect(address.addrinfo.ip_port).to be 42
      end

      it 'uses IPv6' do
        expect(address.addrinfo.ip?).to be true
        expect(address.addrinfo.ipv6?).to be true
        expect(address.addrinfo.ipv4?).to be false
      end
    end

    context 'when called with an Addrinfo' do
      subject(:address) { TCPClient::Address.new(addrinfo) }
      let(:addrinfo) { Addrinfo.tcp('::1', 42) }

      it 'uses the given Addrinfo' do
        expect(address.addrinfo).to eq addrinfo
      end

      it 'points to the given host and port' do
        expect(address.hostname).to eq addrinfo.getnameinfo[0]
        expect(address.addrinfo.ip_port).to be 42
      end

      it 'uses IPv6' do
        expect(address.addrinfo.ip?).to be true
        expect(address.addrinfo.ipv6?).to be true
        expect(address.addrinfo.ipv4?).to be false
      end
    end

    context 'when called with a String' do
      context 'when a host name and port is provided' do
        subject(:address) { TCPClient::Address.new('localhost:42') }

        it 'points to the given host and port' do
          expect(address.hostname).to eq 'localhost'
          expect(address.to_s).to eq 'localhost:42'
          expect(address.addrinfo.ip_port).to be 42
        end

        it 'uses IPv6' do
          expect(address.addrinfo.ip?).to be true
          expect(address.addrinfo.ipv6?).to be true
          expect(address.addrinfo.ipv4?).to be false
        end
      end

      context 'when only a port is provided' do
        subject(:address) { TCPClient::Address.new(':21') }

        it 'points to the given port on localhost' do
          expect(address.hostname).to eq ''
          expect(address.to_s).to eq ':21'
          expect(address.addrinfo.ip_port).to be 21
        end

        it 'uses IPv4' do
          expect(address.addrinfo.ip?).to be true
          expect(address.addrinfo.ipv6?).to be false
          expect(address.addrinfo.ipv4?).to be true
        end
      end

      context 'when an IPv6 address is provided' do
        subject(:address) { TCPClient::Address.new('[::1]:42') }

        it 'points to the given port on localhost' do
          expect(address.hostname).to eq '::1'
          expect(address.to_s).to eq '[::1]:42'
          expect(address.addrinfo.ip_port).to be 42
        end

        it 'uses IPv6' do
          expect(address.addrinfo.ip?).to be true
          expect(address.addrinfo.ipv6?).to be true
          expect(address.addrinfo.ipv4?).to be false
        end
      end
    end
  end

  describe '#to_h' do
    subject(:address) { TCPClient::Address.new('localhost:42') }

    it 'returns itself as an Hash' do
      expect(address.to_h).to eq(host: 'localhost', port: 42)
    end
  end

  describe 'comparison' do
    context 'comparing two equal instances' do
      let(:address_a) { TCPClient::Address.new('localhost:42') }
      let(:address_b) { TCPClient::Address.new('localhost:42') }

      it 'compares to equal' do
        expect(address_a).to eq address_b
      end

      context 'using the == opperator' do
        it 'compares to equal' do
          expect(address_a == address_b).to be true
        end
      end

      context 'using the === opperator' do
        it 'compares to equal' do
          expect(address_a === address_b).to be true
        end
      end
    end

    context 'comparing two non-equal instances' do
      let(:address_a) { TCPClient::Address.new('localhost:42') }
      let(:address_b) { TCPClient::Address.new('localhost:21') }

      it 'compares not to equal' do
        expect(address_a).not_to eq address_b
      end

      context 'using the == opperator' do
        it 'compares not to equal' do
          expect(address_a == address_b).to be false
        end
      end

      context 'using the === opperator' do
        it 'compares not to equal' do
          expect(address_a === address_b).to be false
        end
      end
    end
  end
end
