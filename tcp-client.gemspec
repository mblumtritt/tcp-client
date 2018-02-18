# frozen_string_literal: true

require File.expand_path('../lib/tcp-client/version', __FILE__)

GemSpec = Gem::Specification.new do |spec|
  spec.name = 'tcp-client'
  spec.version = TCPClient::VERSION
  spec.summary = 'A TCP client implementation with working timeout support.'
  spec.description = <<~EOS
    This gem implements a TCP client with (optional) SSL support. The
    motivation of this project is the need to have a _really working_
    easy to use client which can handle time limits correctly. Unlike
    other implementations this client respects given/configurable time
    limits for each method (`connect`, `read`, `write`).
  EOS
  spec.author = 'Mike Blumtritt'
  spec.email = 'mike.blumtritt@invision.de'
  spec.homepage = 'https://github.com/mblumtritt/tcp-client'
  spec.metadata = {'issue_tracker' => 'https://github.com/mblumtritt/tcp-client/issues'}
  spec.rubyforge_project = spec.name

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'

  spec.platform = Gem::Platform::RUBY
  spec.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')
  spec.required_ruby_version = '>= 2.5.0'

  spec.require_paths = %w[lib]

  all_files = %x(git ls-files -z).split(0.chr)
  spec.test_files = all_files.grep(%r{^(spec|test)/})
  spec.files = all_files - spec.test_files

  spec.has_rdoc = false
  spec.extra_rdoc_files = %w[README.md]
end
