# frozen_string_literal: true

if RUBY_VERSION >= "2.7"
  Warning[:deprecated] = true
  Warning[:experimental] = true
end

require "bundler/setup"
require "minitest/autorun"
require "mocha/minitest"
require "pry-byebug"

require_relative "../lib/jat"
