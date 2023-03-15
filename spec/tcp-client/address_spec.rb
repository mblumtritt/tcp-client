# frozen_string_literal: true

require_relative '../helper'

RSpec.describe TCPClient::Address do
  subject(:address) { TCPClient::Address.new(arg) }

  describe '.new' do
    context 'when called with an Integer parameter' do
      let(:arg) { 42 }

      it do
        is_expected.to have_attributes(
          host: 'localhost',
          port: 42,
          to_s: 'localhost:42'
        )
      end

      it 'uses IPv6' do
        expect(address.addrinfo.ipv6?).to be true
      end
    end

    context 'when called with an Addrinfo' do
      let(:arg) { Addrinfo.tcp('::1', 42).freeze }

      it do
        is_expected.to have_attributes(
          addrinfo: arg,
          host: 'localhost',
          port: 42,
          to_s: 'localhost:42'
        )
      end

      it 'uses IPv6' do
        expect(address.addrinfo.ipv6?).to be true
      end
    end

    context 'when called with a String' do
      context 'when a host name and port is provided' do
        let(:arg) { 'localhost:42' }

        it do
          is_expected.to have_attributes(
            host: 'localhost',
            port: 42,
            to_s: 'localhost:42'
          )
        end

        it 'uses IPv6' do
          expect(address.addrinfo.ipv6?).to be true
        end
      end

      context 'when only a port is provided' do
        let(:arg) { ':42' }

        it do
          is_expected.to have_attributes(
            host: 'localhost',
            port: 42,
            to_s: 'localhost:42'
          )
        end

        it 'uses IPv6' do
          expect(address.addrinfo.ipv6?).to be true
        end
      end

      context 'when an IPv6 address is provided' do
        let(:arg) { '[::1]:42' }

        it do
          is_expected.to have_attributes(
            host: '::1',
            port: 42,
            to_s: '[::1]:42'
          )
        end

        it 'uses IPv6' do
          expect(address.addrinfo.ipv6?).to be true
        end
      end
    end

    context 'when called with an unfrozen TCPClient::Address' do
      let(:arg) { TCPClient::Address.new(42) }

      it 'resolves the address info' do
        expect(Addrinfo).to receive(:tcp).with(nil, 42).once.and_call_original
        is_expected.to have_attributes(host: 'localhost', port: 42)
      end

      it 'does not change the source adddress' do
        expect(address.addrinfo.ip?).to be true
        expect(arg).not_to be_frozen
      end
    end

    context 'when called with an frozen TCPClient::Address' do
      let!(:arg) { TCPClient::Address.new(42).freeze }

      it 'uses the already resolved data' do
        expect(Addrinfo).not_to receive(:tcp)
        is_expected.to have_attributes(host: 'localhost', port: 42)
      end
    end
  end

  describe '#to_h' do
    subject(:arg) { 'localhost:42' }

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

      context 'using the == operator' do
        it 'compares to equal' do
          expect(address_a == address_b).to be true
        end
      end

      context 'using the === operator' do
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

      context 'using the == operator' do
        it 'compares not to equal' do
          expect(address_a == address_b).to be false
        end
      end

      context 'using the === operator' do
        it 'compares not to equal' do
          expect(address_a === address_b).to be false
        end
      end
    end
  end
end
