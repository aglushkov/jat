# frozen_string_literal: true

# ARGV is populated with all test file names when running `rake`
# ARGV is not populated when running `ruby -Itest {file}`
# ARGV is not populated when running test by `m` gem - `m {file}`
# ARGV is not populated when running tests by `m` gem with line number - `m {file}:{line_number}`
# jruby and truffleruby have bad simplecov support
if RUBY_ENGINE == "ruby" && ARGV.any?
  require "simplecov"
  SimpleCov.start
end

require "bundler/setup"
require "minitest/autorun"
require "mocha/minitest"

require_relative "../lib/jat"

begin
  require "debug" if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.1.0")
  require "pry-byebug"
rescue LoadError
end
