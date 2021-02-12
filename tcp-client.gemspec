# frozen_string_literal: true

require_relative './lib/tcp-client/version'

GemSpec = Gem::Specification.new do |spec|
  spec.name = 'tcp-client'
  spec.version = TCPClient::VERSION
  spec.author = 'Mike Blumtritt'

  spec.required_ruby_version = '>= 2.7.0'

  spec.summary = 'A TCP client implementation with working timeout support.'
  spec.description = <<~DESCRIPTION
    This gem implements a TCP client with (optional) SSL support. The
    motivation of this project is the need to have a _really working_
    easy to use client which can handle time limits correctly. Unlike
    other implementations this client respects given/configurable time
    limits for each method (`connect`, `read`, `write`).
  DESCRIPTION
  spec.homepage = 'https://github.com/mblumtritt/tcp-client'

  spec.metadata['source_code_uri'] = 'https://github.com/mblumtritt/tcp-client'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/mblumtritt/tcp-client/issues'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'

  all_files = Dir.chdir(__dir__) { `git ls-files -z`.split(0.chr) }
  spec.test_files = all_files.grep(%r{^test/})
  spec.files = all_files - spec.test_files

  spec.extra_rdoc_files = %w[README.md]
end
