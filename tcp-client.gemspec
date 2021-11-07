# frozen_string_literal: true

require_relative './lib/tcp-client/version'

Gem::Specification.new do |spec|
  spec.name = 'tcp-client'
  spec.version = TCPClient::VERSION
  spec.author = 'Mike Blumtritt'

  spec.required_ruby_version = '>= 2.7.0'

  spec.summary = 'A TCP client implementation with working timeout support.'
  spec.description = <<~DESCRIPTION
    This Gem implements a TCP client with (optional) SSL support.
    It is an easy to use, versatile configurable client that can correctly
    handle time limits.
    Unlike other implementations, this client respects
    predefined/configurable time limits for each method
    (`connect`, `read`, `write`). Deadlines for a sequence of read/write
    actions can also be monitored.
  DESCRIPTION
  spec.homepage = 'https://github.com/mblumtritt/tcp-client'
  spec.license = 'BSD-3-Clause'

  spec.metadata['source_code_uri'] = 'https://github.com/mblumtritt/tcp-client'
  spec.metadata['bug_tracker_uri'] =
    'https://github.com/mblumtritt/tcp-client/issues'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'

  all_files = Dir.chdir(__dir__) { `git ls-files -z`.split(0.chr) }
  spec.test_files = all_files.grep(%r{^test/})
  spec.files = all_files - spec.test_files

  spec.extra_rdoc_files = %w[README.md LICENSE]
end
