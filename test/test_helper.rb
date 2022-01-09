# frozen_string_literal: true

# ARGV is populated with all test file names when running `rake`
# ARGV is not populated when running `ruby -Itest {file}`
# ARGV is not populated when running test by `m` gem - `m {file}`
# ARGV is not populated when running tests by `m` gem with line number - `m {file}:{line_number}`
if ARGV.any?
  require "simplecov"
  SimpleCov.start
end

require "bundler/setup"
require "minitest/autorun"
require "mocha/minitest"
require "pry-byebug"

require_relative "../lib/jat"
