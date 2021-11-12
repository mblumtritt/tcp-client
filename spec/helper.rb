# frozen_string_literal: true

require 'rspec/core'
require_relative '../lib/tcp-client'

$stdout.sync = $stderr.sync = true

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
end
