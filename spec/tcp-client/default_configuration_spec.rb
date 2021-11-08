# frozen_string_literal: true

require_relative '../helper'

RSpec.describe 'TCPClient.configure' do
  it 'is the default configuration' do
    expect(TCPClient.configure).to be TCPClient::Configuration.default
  end

  context 'called with parameters' do
    it 'creates a new configuratiion' do
      expect(TCPClient::Configuration).to receive(:create).once.with(a: 1, b: 2)
      TCPClient.configure(a: 1, b: 2)
    end

    it 'returns the new configuratiion' do
      expect(TCPClient::Configuration).to receive(:create).and_return(:a_result)
      TCPClient.configure(something: :new)
      expect(TCPClient::Configuration.default).to be :a_result
    end
  end
end
