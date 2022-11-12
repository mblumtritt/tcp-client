# frozen_string_literal: true

require 'rspec/core'
require_relative '../lib/tcp-client'

$stdout.sync = $stderr.sync = $VERBOSE = true
RSpec.configure(&:disable_monkey_patching!)
