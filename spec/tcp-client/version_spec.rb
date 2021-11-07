# frozen_string_literal: true

require_relative '../helper'

RSpec.describe 'TCPClient::VERSION' do
  it 'is a valid version string' do
    expect(TCPClient::VERSION).to match(/\d+\.\d+\.\d+/)
  end

  it 'is frozen' do
    expect(TCPClient::VERSION.frozen?).to be true
  end
end
