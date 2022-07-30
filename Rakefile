# frozen_string_literal: true

require 'rake/clean'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

$stdout.sync = $stderr.sync = true

CLEAN << '.yardoc'
CLOBBER << 'prj' << 'doc'

task(:default) { exec('rake --tasks') }

RSpec::Core::RakeTask.new(:test) { |task| task.ruby_opts = %w[-w] }

YARD::Rake::YardocTask.new do |task|
  task.stats_options = %w[--list-undoc]
end

desc 'Run YARD development server'
task('yard:dev' => :clobber) { exec('yard server --reload') }
