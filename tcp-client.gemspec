# frozen_string_literal: true

require_relative 'lib/tcp-client/version'

Gem::Specification.new do |spec|
  spec.name = 'tcp-client'
  spec.version = TCPClient::VERSION
  spec.summary = 'Use your TCP connections with working timeout.'
  spec.description = <<~DESCRIPTION
    This gem implements a customizable TCP client class that gives you control
    over time limits. You can set time limits for individual read or write calls
    or set a deadline for entire call sequences.
    It has a very small footprint, no dependencies and is easily useable.
  DESCRIPTION

  spec.author = 'Mike Blumtritt'
  spec.license = 'BSD-3-Clause'
  spec.homepage = 'https://github.com/mblumtritt/tcp-client'
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/tcp-client'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.required_ruby_version = '>= 3.0.0'

  spec.files = Dir['lib/**/*'] << '.yardopts'
  spec.extra_rdoc_files = %w[README.md LICENSE]
end
