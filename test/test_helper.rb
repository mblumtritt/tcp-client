require 'minitest/autorun'
require 'minitest/parallel'
require_relative '../lib/tcp-client'

$stdout.sync = $stderr.sync = true

class Test < Minitest::Test
  parallelize_me!
end
