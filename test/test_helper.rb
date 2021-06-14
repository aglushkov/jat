# frozen_string_literal: true

require "simplecov"
SimpleCov.start

if RUBY_VERSION >= "2.7"
  Warning[:deprecated] = true
  Warning[:experimental] = true
end

require "bundler/setup"
require "minitest/autorun"
require "mocha/minitest"
require "pry-byebug"

require_relative "../lib/jat"
