require "bundler/gem_tasks"
require 'rake/testtask'
require 'open3'

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

namespace :bump do
  def bump(level)
    # Raise an error when  uncommited files exist.
    sh 'git', 'diff', '--quiet'
    sh 'git', 'checkout', 'origin/master'

    file = 'lib/iro/version.rb'
    re = /VERSION\s*=\s*['"](.+)['"]/

    content = File.read(file)
    version = content[re, 1].split('.').map(&:to_i)
    case level
    when :patch
      version[2] += 1
    when :minor
      version[2] = 0
      version[1] += 1
    when :major
      version[2] = 0
      version[1] = 0
      version[0] += 1
    else
      raise "Unknown level: #{level}"
    end
    v = version.map(&:to_s).join('.')
    content[re, 1] = v
    File.write(file, content)

    sh 'git', 'commit', '-am', "Bump up version to #{v}"
    sh 'git', 'tag', "v#{v}"
    sh 'git', 'push', "origin", 'HEAD:master', '--tags'
    Rake::Task['release:rubygem_push'].invoke
  end

  task(:patch) { bump :patch }
  task(:minor) { bump :minor }
  task(:major) { bump :major }
end
