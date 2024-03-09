# frozen_string_literal: true

$stdout.sync = $stderr.sync = true

require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:test) { _1.ruby_opts = %w[-w] }

require 'yard'
YARD::Rake::YardocTask.new(:doc) { _1.stats_options = %w[--list-undoc] }

desc 'Run YARD development server'
task('doc:dev' => :clobber) { exec('yard server --reload') }

CLEAN << '.yardoc'
CLOBBER << 'doc'

task(:default) { exec('rake --tasks') }
