# frozen_string_literal: true

require 'rake/clean'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

$stdout.sync = $stderr.sync = true

CLEAN << '.yardoc'
CLOBBER << 'prj' << 'doc'

task(:default) { exec('rake --tasks') }
task(test: :spec)
RSpec::Core::RakeTask.new { |task| task.ruby_opts = %w[-w] }
YARD::Rake::YardocTask.new { |task| task.stats_options = %w[--list-undoc] }
