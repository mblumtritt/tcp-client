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

      it do
        is_expected.to have_attributes(
          buffered: true,
          keep_alive: true,
          reverse_lookup: true,
          normalize_network_errors: false,
          ssl?: false,
          connect_timeout: nil,
          read_timeout: nil,
          write_timeout: nil,
          connect_timeout_error: TCPClient::ConnectTimeoutError,
          read_timeout_error: TCPClient::ReadTimeoutError,
          write_timeout_error: TCPClient::WriteTimeoutError
        )
      end
    end

    context 'when options are given' do
      let(:options) { double(:options) }

      it 'calls #configure with given options' do
        expect_any_instance_of(TCPClient::Configuration).to receive(
          :configure
        ).once.with(options)

        TCPClient::Configuration.new(options)
      end
    end
  end

  describe '#configure' do
    subject(:configuration) do
      TCPClient::Configuration.new.configure(
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

    context 'with valid options' do
      it do
        is_expected.to have_attributes(
          buffered: false,
          keep_alive: false,
          reverse_lookup: false,
          normalize_network_errors: true,
          ssl?: true,
          connect_timeout: 60,
          read_timeout: 60,
          write_timeout: 60,
          connect_timeout_error: custom_error,
          read_timeout_error: custom_error,
          write_timeout_error: custom_error
        )
      end

      it 'allows to configure dedicated timeout values' do
        configuration.configure(
          connect_timeout: 21,
          read_timeout: 42,
          write_timeout: 84
        )
        is_expected.to have_attributes(
          connect_timeout: 21,
          read_timeout: 42,
          write_timeout: 84
        )
      end

      it 'allows to configure dedicated timeout errors' do
        custom_connect = Class.new(StandardError)
        custom_read = Class.new(StandardError)
        custom_write = Class.new(StandardError)
        configuration.configure(
          connect_timeout_error: custom_connect,
          read_timeout_error: custom_read,
          write_timeout_error: custom_write
        )
        is_expected.to have_attributes(
          connect_timeout_error: custom_connect,
          read_timeout_error: custom_read,
          write_timeout_error: custom_write
        )
      end
    end

    context 'when an invalid attribute is given' do
      it 'raises an error' do
        expect { configuration.configure(invalid: :value) }.to raise_error(
          TCPClient::UnknownAttributeError
        )
      end
    end

    context 'when no exception class is used to configure a timeout error' do
      it 'raises with invalid connect_timeout_error' do
        expect do
          configuration.configure(connect_timeout_error: double(:something))
        end.to raise_error(TCPClient::NotAnExceptionError)
      end

      it 'raises with invalid read_timeout_error' do
        expect do
          configuration.configure(read_timeout_error: double(:something))
        end.to raise_error(TCPClient::NotAnExceptionError)
      end

      it 'raises with invalid write_timeout_error' do
        expect do
          configuration.configure(write_timeout_error: double(:something))
        end.to raise_error(TCPClient::NotAnExceptionError)
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
      expect(subject).to have_attributes(
        buffered: false,
        connect_timeout: 1,
        read_timeout: 2,
        write_timeout: 3,
        ssl?: true,
        ssl_params: {
          min_version: :TLS1_2,
          max_version: :TLS1_3
        }
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

      it 'compares to equal with == operator' do
        expect(config_a == config_b).to be true
      end

      it 'compares to equal with === operator' do
        expect(config_a === config_b).to be true
      end
    end

    context 'comparing two non-equal instances' do
      let(:config_a) { TCPClient::Configuration.new(timeout: 10) }
      let(:config_b) { TCPClient::Configuration.new(timeout: 20) }

      it 'compares not to equal' do
        expect(config_a).not_to eq config_b
      end

      it 'compares not to equal with == operator' do
        expect(config_a == config_b).to be false
      end

      it 'compares not to equal with === operator' do
        expect(config_a === config_b).to be false
      end
    end
  end
end
