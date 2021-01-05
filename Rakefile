# frozen_string_literal: true

# https://github.com/ruby/rake/blob/master/Rakefile

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

begin
  require "bundler/gem_tasks"
rescue LoadError
end

require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = false
  t.warning = false
end

task default: :test
