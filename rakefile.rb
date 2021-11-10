# frozen_string_literal: true

require 'rake/clean'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

$stdout.sync = $stderr.sync = true

CLOBBER << 'prj'

task(:default) { exec('rake --tasks') }

RSpec::Core::RakeTask.new do |task|
  task.ruby_opts = %w[-w]
end
