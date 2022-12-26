# frozen_string_literal: true

$stdout.sync = $stderr.sync = true

require 'rake/clean'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

CLEAN << '.yardoc'
CLOBBER << 'doc'

task(:default) { exec('rake --tasks') }

RSpec::Core::RakeTask.new(:test) { |task| task.ruby_opts = %w[-w] }

YARD::Rake::YardocTask.new(:doc) do |task|
  task.stats_options = %w[--list-undoc]
end

desc 'Run YARD development server'
task('doc:dev' => :clobber) { exec('yard server --reload') }
