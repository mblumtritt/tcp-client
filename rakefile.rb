# frozen_string_literal: true

require 'rake/clean'
require 'rake/testtask'
require 'bundler/gem_tasks'

$stdout.sync = $stderr.sync = true

CLOBBER << 'prj'

task(:default) { exec('rake --tasks') }

Rake::TestTask.new(:test) do |task|
  task.pattern = 'test/**/*_test.rb'
  task.warning = task.verbose = true
end
