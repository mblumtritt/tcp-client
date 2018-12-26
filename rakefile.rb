# frozen_string_literal: true

require 'rake/clean'
require 'rake/testtask'
require 'bundler/gem_tasks'

STDOUT.sync = STDERR.sync = true

CLOBBER << 'prj'

Rake::TestTask.new(:test) do |t|
  t.ruby_opts = %w[-w]
  t.verbose = true
  t.test_files = FileList['test/**/*_test.rb']
end

task :default do
  exec("#{$PROGRAM_NAME} --tasks")
end
