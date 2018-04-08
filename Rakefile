require "bundler/gem_tasks"
require 'rake/testtask'
task :default => :test

Rake::TestTask.new do |test|
  test.libs << 'test'
  test.test_files = Dir['test/**/*_test.rb']
  test.verbose = true
end

task :smoke do
  sh 'bin/smoke', 'tric/trick2013'
  sh 'bin/smoke', 'tric/trick2015'
  sh 'bin/smoke', 'ruby/ruby', 'trunk'
  sh 'bin/smoke', 'gitlabhq/gitlabhq'
  sh 'bin/smoke', 'rails/rails'
end
