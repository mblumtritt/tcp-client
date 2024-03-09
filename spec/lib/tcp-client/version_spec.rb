# frozen_string_literal: true

RSpec.describe TCPClient::VERSION do
  it { is_expected.to match(/\A[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\z/) }
  it { is_expected.to be_frozen }
end
