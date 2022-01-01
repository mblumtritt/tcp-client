# frozen_string_literal: true

require_relative 'helper'

SOCKET_ERRORS = [
  Errno::EADDRNOTAVAIL,
  Errno::ECONNABORTED,
  Errno::ECONNREFUSED,
  Errno::ECONNRESET,
  Errno::EHOSTUNREACH,
  Errno::EINVAL,
  Errno::ENETUNREACH,
  Errno::EPIPE,
  IOError,
  SocketError,
  ::OpenSSL::SSL::SSLError
].freeze

RSpec.describe TCPClient do
  subject(:client) { TCPClient.new.connect('localhost:1234', configuration) }
  let(:configuration) do
    TCPClient::Configuration.create(buffered: false, reverse_lookup: false)
  end

  describe 'a new instance' do
    subject(:client) { TCPClient.new }

    it 'is closed' do
      expect(client.closed?).to be true
    end

    it 'has no address' do
      expect(client.address).to be_nil
    end

    it 'returns no address string' do
      expect(client.to_s).to eq ''
    end

    it 'has no configuration' do
      expect(client.configuration).to be_nil
    end

    it 'failes when read is called' do
      expect { client.read(42) }.to raise_error(TCPClient::NotConnectedError)
    end

    it 'failes when write is called' do
      expect { client.write('?!') }.to raise_error(TCPClient::NotConnectedError)
    end

    it 'can be closed' do
      expect_any_instance_of(::Socket).not_to receive(:close)
      expect(client.close).to be client
    end

    it 'can be flushed' do
      expect_any_instance_of(::Socket).not_to receive(:flush)
      expect(client.flush).to be client
    end
  end

  describe 'a connected instance' do
    before { allow_any_instance_of(::Socket).to receive(:connect) }

    it 'is not closed' do
      expect(client.closed?).to be false
    end

    it 'has an address' do
      expect(client.address).to be_a TCPClient::Address
    end

    it 'returns an address string' do
      expect(client.to_s).to eq 'localhost:1234'
    end

    it 'uses the given configuration' do
      expect(client.configuration).to be configuration
    end

    it 'allows to read data' do
      result = '-' * 42
      allow_any_instance_of(::Socket).to receive(:read)
        .with(42)
        .and_return(result)
      expect(client.read(42)).to be result
    end

    it 'allows to write data' do
      allow_any_instance_of(::Socket).to receive(:write)
        .with('!' * 21)
        .and_return(21)
      expect(client.write('!' * 21)).to be 21
    end

    it 'can be closed' do
      expect_any_instance_of(::Socket).to receive(:close)
      expect(client.close).to be client
    end

    it 'can be flushed' do
      expect_any_instance_of(::Socket).to receive(:flush)
      expect(client.flush).to be client
    end
  end

  describe 'an instance after #connect failed' do
    subject(:client) do
      TCPClient.new.tap do |instance|
        instance.connect('', configuration)
      rescue StandardError
        Errno::EADDRNOTAVAIL
      end
    end

    it 'is closed' do
      expect(client.closed?).to be true
    end

    it 'has an address' do
      expect(client.address).to be_a TCPClient::Address
    end

    it 'returns an address string' do
      expect(client.to_s).to eq 'localhost:0'
    end

    it 'uses the given configuration' do
      expect(client.configuration).to be configuration
    end

    it 'failes when read is called' do
      expect { client.read(42) }.to raise_error(TCPClient::NotConnectedError)
    end

    it 'failes when write is called' do
      expect { client.write('?!') }.to raise_error(TCPClient::NotConnectedError)
    end

    it 'can be closed' do
      expect_any_instance_of(::Socket).not_to receive(:close)
      expect(client.close).to be client
    end

    it 'can be flushed' do
      expect_any_instance_of(::Socket).not_to receive(:flush)
      expect(client.flush).to be client
    end
  end

  xdescribe '.open' do
  end

  xdescribe '.with_deadline' do
  end

  context 'when not using SSL' do
    describe '#connect' do
      it 'configures the socket' do
        expect_any_instance_of(::Socket).to receive(:sync=).once.with(true)
        expect_any_instance_of(::Socket).to receive(:setsockopt)
          .once
          .with(:TCP, :NODELAY, 1)
        expect_any_instance_of(::Socket).to receive(:setsockopt)
          .once
          .with(:SOCKET, :KEEPALIVE, 1)
        expect_any_instance_of(::Socket).to receive(:do_not_reverse_lookup=)
          .once
          .with(false)
        expect_any_instance_of(::Socket).to receive(:connect)
        TCPClient.new.connect('localhost:1234', configuration)
      end

      context 'when a timeout is specified' do
        it 'checks the time' do
          expect_any_instance_of(::Socket).to receive(:connect_nonblock)
            .once
            .with(kind_of(String), exception: false)
          TCPClient.new.connect('localhost:1234', configuration, timeout: 10)
        end

        context 'when the connection can not be established in time' do
          before do
            allow_any_instance_of(::Socket).to receive(:connect_nonblock)
              .and_return(:wait_writable)
          end

          it 'raises an exception' do
            expect do
              TCPClient.new.connect(
                'localhost:1234',
                configuration,
                timeout: 0.25
              )
            end.to raise_error(TCPClient::ConnectTimeoutError)
          end

          it 'allows to raise a custom exception' do
            exception = Class.new(StandardError)
            expect do
              TCPClient.new.connect(
                'localhost:1234',
                configuration,
                timeout: 0.25,
                exception: exception
              )
            end.to raise_error(exception)
          end
        end
      end

      context 'when a SocketError appears' do
        it 'does not handle it' do
          allow_any_instance_of(::Socket).to receive(:connect) {
            raise SocketError
          }
          expect do
            TCPClient.new.connect('localhost:1234', configuration)
          end.to raise_error(SocketError)
        end

        context 'when normalize_network_errors is configured' do
          let(:configuration) do
            TCPClient::Configuration.create(normalize_network_errors: true)
          end

          SOCKET_ERRORS.each do |error_class|
            it "raises a TCPClient::NetworkError when a #{error_class} appeared" do
              allow_any_instance_of(::Socket).to receive(:connect) {
                raise error_class
              }
              expect do
                TCPClient.new.connect('localhost:1234', configuration)
              end.to raise_error(TCPClient::NetworkError)
            end
          end
        end
      end
    end

    describe '#read' do
      let(:data) { 'some bytes' }
      let(:data_size) { data.bytesize }

      before { allow_any_instance_of(::Socket).to receive(:connect) }

      it 'reads from socket' do
        expect_any_instance_of(::Socket).to receive(:read)
          .once
          .with(nil)
          .and_return(data)
        expect(client.read).to be data
      end

      context 'when a number of bytes is specified' do
        it 'reads the requested number of bytes' do
          expect_any_instance_of(::Socket).to receive(:read)
            .once
            .with(data_size)
            .and_return(data)
          expect(client.read(data_size)).to be data
        end
      end

      context 'when a timeout is specified' do
        it 'checks the time' do
          expect_any_instance_of(::Socket).to receive(:read_nonblock)
            .and_return(data)
          expect(client.read(timeout: 10)).to be data
        end

        context 'when data can not be fetched in a single chunk' do
          it 'reads chunk by chunk' do
            expect_any_instance_of(::Socket).to receive(:read_nonblock)
              .once
              .with(instance_of(Integer), exception: false)
              .and_return(data)
            expect_any_instance_of(::Socket).to receive(:read_nonblock)
              .once
              .with(instance_of(Integer), exception: false)
              .and_return(data)
            expect(client.read(data_size * 2, timeout: 10)).to eq data * 2
          end
        end

        context 'when the data can not be read in time' do
          before do
            allow_any_instance_of(::Socket).to receive(:read_nonblock)
              .and_return(:wait_readable)
          end
          it 'raises an exception' do
            expect { client.read(timeout: 0.25) }.to raise_error(
              TCPClient::ReadTimeoutError
            )
          end

          it 'allows to raise a custom exception' do
            exception = Class.new(StandardError)
            expect do
              client.read(timeout: 0.25, exception: exception)
            end.to raise_error(exception)
          end
        end
      end

      context 'when a SocketError appears' do
        it 'does not handle it' do
          allow_any_instance_of(::Socket).to receive(:read) {
            raise SocketError
          }
          expect { client.read(10) }.to raise_error(SocketError)
        end

        context 'when normalize_network_errors is configured' do
          let(:configuration) do
            TCPClient::Configuration.create(normalize_network_errors: true)
          end

          SOCKET_ERRORS.each do |error_class|
            it "raises a TCPClient::NetworkError when a #{error_class} appeared" do
              allow_any_instance_of(::Socket).to receive(:read) {
                raise error_class
              }
              expect { client.read(12) }.to raise_error(TCPClient::NetworkError)
            end
          end
        end
      end
    end

    describe '#write' do
      let(:data) { 'some bytes' }
      let(:data_size) { data.bytesize }

      before { allow_any_instance_of(::Socket).to receive(:connect) }

      it 'writes to the socket' do
        expect_any_instance_of(::Socket).to receive(:write)
          .once
          .with(data)
          .and_return(data_size)
        expect(client.write(data)).to be data_size
      end

      context 'when multiple data chunks are given' do
        it 'writes each chunk' do
          expect_any_instance_of(::Socket).to receive(:write)
            .once
            .with(data, data)
            .and_return(data_size * 2)
          expect(client.write(data, data)).to be data_size * 2
        end
      end

      context 'when a timeout is specified' do
        it 'checks the time' do
          expect_any_instance_of(::Socket).to receive(:write_nonblock)
            .and_return(data_size)
          expect(client.write(data, timeout: 10)).to be data_size
        end

        context 'when data can not be written in a single chunk' do
          let(:chunk1) { '1234567890' }
          let(:chunk2) { '12345' }
          let(:data1) { chunk1 + chunk2 }
          let(:chunk3) { 'abcdefghijklm' }
          let(:chunk4) { 'ABCDE' }
          let(:data2) { chunk3 + chunk4 }

          it 'writes chunk by chunk and part by part' do
            expect_any_instance_of(::Socket).to receive(:write_nonblock)
              .once
              .with(data1, exception: false)
              .and_return(chunk1.bytesize)
            expect_any_instance_of(::Socket).to receive(:write_nonblock)
              .once
              .with(chunk2, exception: false)
              .and_return(chunk2.bytesize)
            expect_any_instance_of(::Socket).to receive(:write_nonblock)
              .once
              .with(data2, exception: false)
              .and_return(chunk3.bytesize)
            expect_any_instance_of(::Socket).to receive(:write_nonblock)
              .once
              .with(chunk4, exception: false)
              .and_return(chunk4.bytesize)

            expect(client.write(data1, data2, timeout: 10)).to be(
              data1.bytesize + data2.bytesize
            )
          end
        end

        context 'when the data can not be written in time' do
          before do
            allow_any_instance_of(::Socket).to receive(:write_nonblock)
              .and_return(:wait_writable)
          end
          it 'raises an exception' do
            expect { client.write(data, timeout: 0.25) }.to raise_error(
              TCPClient::WriteTimeoutError
            )
          end

          it 'allows to raise a custom exception' do
            exception = Class.new(StandardError)
            expect do
              client.write(data, timeout: 0.25, exception: exception)
            end.to raise_error(exception)
          end
        end
      end

      context 'when a SocketError appears' do
        before { allow_any_instance_of(::Socket).to receive(:connect) }

        it 'does not handle it' do
          allow_any_instance_of(::Socket).to receive(:write) {
            raise SocketError
          }
          expect { client.write('some data') }.to raise_error(SocketError)
        end

        context 'when normalize_network_errors is configured' do
          let(:configuration) do
            TCPClient::Configuration.create(normalize_network_errors: true)
          end

          SOCKET_ERRORS.each do |error_class|
            it "raises a TCPClient::NetworkError when a #{error_class} appeared" do
              allow_any_instance_of(::Socket).to receive(:write) {
                raise error_class
              }
              expect { client.write('some data') }.to raise_error(
                TCPClient::NetworkError
              )
            end
          end
        end
      end
    end

    describe '#with_deadline' do
      subject(:client) { TCPClient.new }
      let(:configuration) { TCPClient::Configuration.create(timeout: 60) }

      before do
        allow_any_instance_of(::Socket).to receive(:connect_nonblock)
        allow_any_instance_of(::Socket).to receive(:read_nonblock) do |_, size|
          'r' * size
        end
        allow_any_instance_of(::Socket).to receive(
          :write_nonblock
        ) do |_, data|
          data.bytesize
        end
      end

      it 'allows to use a timeout value for all actions in the given block' do
        expect_any_instance_of(::Socket).to receive(:connect_nonblock)
          .once
          .with(kind_of(String), exception: false)
        expect_any_instance_of(::Socket).to receive(:read_nonblock)
          .once
          .with(instance_of(Integer), exception: false)
          .and_return('123456789012abcdefgAB')
        expect_any_instance_of(::Socket).to receive(:write_nonblock)
          .once
          .with('123456', exception: false)
          .and_return(6)
        expect_any_instance_of(::Socket).to receive(:read_nonblock)
          .once
          .with(instance_of(Integer), exception: false)
          .and_return('CDEFG')
        expect_any_instance_of(::Socket).to receive(:write_nonblock)
          .once
          .with('abc', exception: false)
          .and_return(3)
        expect_any_instance_of(::Socket).to receive(:write_nonblock)
          .once
          .with('ABC', exception: false)
          .and_return(3)
        expect_any_instance_of(::Socket).to receive(:write_nonblock)
          .once
          .with('ABCDEF', exception: false)
          .and_return(6)

        client.with_deadline(10) do
          expect(client.connect('localhost:1234', configuration)).to be client
          expect(client.read(12)).to eq '123456789012'
          expect(client.write('123456')).to be 6
          expect(client.read(7)).to eq 'abcdefg'
          expect(client.read(7)).to eq 'ABCDEFG'
          expect(client.write('abc')).to be 3
          expect(client.write('ABC', 'ABCDEF')).to be 9
        end
      end

      context 'when called without a block' do
        it 'raises an exception' do
          expect { client.with_deadline(0.25) }.to raise_error(ArgumentError)
        end
      end

      context 'when #connect fails' do
        it 'raises an exception' do
          expect_any_instance_of(::Socket).to receive(:connect_nonblock)
            .and_return(:wait_writable)
          expect do
            client.with_deadline(0.25) do
              client.connect('localhost:1234', configuration)
              client.read(12)
              client.write('Hello World!')
            end
          end.to raise_error(TCPClient::ConnectTimeoutError)
        end
      end

      context 'when #read fails' do
        it 'raises an exception' do
          expect_any_instance_of(::Socket).to receive(:read_nonblock)
            .and_return(:wait_readable)
          expect do
            client.with_deadline(0.25) do
              client.connect('localhost:1234', configuration)
              client.write('Hello World!')
              client.read(12)
            end
          end.to raise_error(TCPClient::ReadTimeoutError)
        end
      end

      context 'when #write fails' do
        it 'raises an exception' do
          expect_any_instance_of(::Socket).to receive(:write_nonblock)
            .and_return(:wait_writable)
          expect do
            client.with_deadline(0.25) do
              client.connect('localhost:1234', configuration)
              client.read(12)
              client.write('Hello World!')
            end
          end.to raise_error(TCPClient::WriteTimeoutError)
        end
      end
    end
  end

  context 'when using SSL' do
    let(:configuration) do
      TCPClient::Configuration.create(
        buffered: false,
        reverse_lookup: false,
        ssl: {
          min_version: :TLS1_2,
          max_version: :TLS1_3
        }
      )
    end

    before do
      allow_any_instance_of(::Socket).to receive(:connect)
      allow_any_instance_of(::OpenSSL::SSL::SSLSocket).to receive(:connect)
    end

    describe '#connect' do
      it 'configures the SSL socket' do
        # this produces a mock warning :(
        # expect_any_instance_of(::OpenSSL::SSL::SSLContext).to receive(
        #     :set_params
        #   )
        #   .once
        #   .with(ssl_version: :TLSv1_2)
        #   .and_call_original
        expect_any_instance_of(::OpenSSL::SSL::SSLSocket).to receive(
            :sync_close=
          )
          .once
          .with(true)
          .and_call_original
        expect_any_instance_of(::OpenSSL::SSL::SSLSocket).to receive(
            :post_connection_check
          )
          .once
          .with('localhost')

        TCPClient.new.connect('localhost:1234', configuration)
      end
    end
  end
end
