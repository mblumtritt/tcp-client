# frozen_string_literal: true

require_relative '../helper'

RSpec.describe TCPClient::Configuration do
  describe '.create' do
    it 'yields a configuration' do
      TCPClient::Configuration.create do |cfg|
        expect(cfg).to be_a TCPClient::Configuration
      end
    end

    it 'returns the configuration' do
      yielded_cfg = nil
      result = TCPClient::Configuration.create { |cfg| yielded_cfg = cfg }
      expect(result).to be yielded_cfg
    end
  end

  describe '.new' do
    context 'without any parameter' do
      subject(:configuration) { TCPClient::Configuration.new }

      it 'allows buffering' do
        expect(configuration.buffered).to be true
      end

      it 'allows keep alive signals' do
        expect(configuration.keep_alive).to be true
      end

      it 'allows reverse address lokup' do
        expect(configuration.reverse_lookup).to be true
      end

      it 'does not allow to normalize network errors' do
        expect(configuration.normalize_network_errors).to be false
      end

      it 'does not allow SSL connections' do
        expect(configuration.ssl?).to be false
      end

      it 'configures no timeout values' do
        expect(configuration.connect_timeout).to be_nil
        expect(configuration.read_timeout).to be_nil
        expect(configuration.write_timeout).to be_nil
      end

      it 'configures default errors' do
        expect(
          configuration.connect_timeout_error
        ).to be TCPClient::ConnectTimeoutError
        expect(
          configuration.read_timeout_error
        ).to be TCPClient::ReadTimeoutError
        expect(
          configuration.write_timeout_error
        ).to be TCPClient::WriteTimeoutError
      end
    end

    context 'with valid options' do
      subject(:configuration) do
        TCPClient::Configuration.new(
          buffered: false,
          keep_alive: false,
          reverse_lookup: false,
          normalize_network_errors: true,
          ssl: true,
          timeout: 60,
          timeout_error: custom_error
        )
      end
      let(:custom_error) { Class.new(StandardError) }

      it 'allows to configure buffering' do
        expect(configuration.buffered).to be false
      end

      it 'allows to configure keep alive signals' do
        expect(configuration.keep_alive).to be false
      end

      it 'allows to configure reverse address lokup' do
        expect(configuration.reverse_lookup).to be false
      end

      it 'allows to configure to normalize network errors' do
        expect(configuration.normalize_network_errors).to be true
      end

      it 'allows to configures SSL connections' do
        expect(configuration.ssl?).to be true
      end

      it 'allows to configure no timeout values' do
        expect(configuration.connect_timeout).to be 60
        expect(configuration.read_timeout).to be 60
        expect(configuration.write_timeout).to be 60
      end

      it 'allows to configure timeout errors' do
        expect(configuration.connect_timeout_error).to be custom_error
        expect(configuration.read_timeout_error).to be custom_error
        expect(configuration.write_timeout_error).to be custom_error
      end

      it 'allows to configure dedicated timeout values' do
        config =
          TCPClient::Configuration.new(
            connect_timeout: 21,
            read_timeout: 42,
            write_timeout: 84
          )
        expect(config.connect_timeout).to be 21
        expect(config.read_timeout).to be 42
        expect(config.write_timeout).to be 84
      end

      it 'allows to configure dedicated timeout errors' do
        custom_connect = Class.new(StandardError)
        custom_read = Class.new(StandardError)
        custom_write = Class.new(StandardError)
        config =
          TCPClient::Configuration.new(
            connect_timeout_error: custom_connect,
            read_timeout_error: custom_read,
            write_timeout_error: custom_write
          )
        expect(config.connect_timeout_error).to be custom_connect
        expect(config.read_timeout_error).to be custom_read
        expect(config.write_timeout_error).to be custom_write
      end

      it 'raises when no exception class is used to configure a timeout error' do
        expect do
          TCPClient::Configuration.new(
            connect_timeout_error: double(:something)
          )
        end.to raise_error(TCPClient::NotAnExceptionError)
        expect do
          TCPClient::Configuration.new(read_timeout_error: double(:something))
        end.to raise_error(TCPClient::NotAnExceptionError)
        expect do
          TCPClient::Configuration.new(write_timeout_error: double(:something))
        end.to raise_error(TCPClient::NotAnExceptionError)
      end
    end

    context 'with invalid attribte' do
      it 'raises an error' do
        expect { TCPClient::Configuration.new(invalid: :value) }.to raise_error(
          TCPClient::UnknownAttributeError
        )
      end
    end
  end

  describe '#to_h' do
    subject(:configuration) do
      TCPClient::Configuration.new(
        buffered: false,
        connect_timeout: 1,
        read_timeout: 2,
        write_timeout: 3,
        ssl: {
          min_version: :TLS1_2,
          max_version: :TLS1_3
        }
      )
    end

    it 'returns itself as an Hash' do
      expect(configuration.to_h).to eq(
        buffered: false,
        keep_alive: true,
        reverse_lookup: true,
        connect_timeout: 1,
        connect_timeout_error: TCPClient::ConnectTimeoutError,
        read_timeout: 2,
        read_timeout_error: TCPClient::ReadTimeoutError,
        write_timeout: 3,
        write_timeout_error: TCPClient::WriteTimeoutError,
        normalize_network_errors: false,
        ssl_params: {
          min_version: :TLS1_2,
          max_version: :TLS1_3
        }
      )
    end
  end

  describe '#dup' do
    subject(:duplicate) { configuration.dup }
    let(:configuration) do
      TCPClient::Configuration.new(
        buffered: false,
        connect_timeout: 1,
        read_timeout: 2,
        write_timeout: 3,
        ssl: {
          min_version: :TLS1_2,
          max_version: :TLS1_3
        }
      )
    end

    it 'returns a new instance' do
      expect(duplicate).to be_a TCPClient::Configuration
      expect(duplicate.__id__).not_to eq configuration.__id__
    end

    it 'contains same values as the original' do
      expect(duplicate.buffered).to be false
      expect(duplicate.connect_timeout).to be 1
      expect(duplicate.read_timeout).to be 2
      expect(duplicate.write_timeout).to be 3
      expect(duplicate.ssl?).to be true
      expect(duplicate.ssl_params).to eq(
        min_version: :TLS1_2,
        max_version: :TLS1_3
      )
    end
  end

  describe 'comparison' do
    context 'comparing two equal instances' do
      let(:config_a) { TCPClient::Configuration.new(timeout: 10) }
      let(:config_b) { TCPClient::Configuration.new(timeout: 10) }

      it 'compares to equal' do
        expect(config_a).to eq config_b
      end

      context 'using the == opperator' do
        it 'compares to equal' do
          expect(config_a == config_b).to be true
        end
      end

      context 'using the === opperator' do
        it 'compares to equal' do
          expect(config_a === config_b).to be true
        end
      end
    end

    context 'comparing two non-equal instances' do
      let(:config_a) { TCPClient::Configuration.new(timeout: 10) }
      let(:config_b) { TCPClient::Configuration.new(timeout: 20) }

      it 'compares not to equal' do
        expect(config_a).not_to eq config_b
      end

      context 'using the == opperator' do
        it 'compares not to equal' do
          expect(config_a == config_b).to be false
        end
      end

      context 'using the === opperator' do
        it 'compares not to equal' do
          expect(config_a === config_b).to be false
        end
      end
    end
  end
end
