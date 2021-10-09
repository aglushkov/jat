# frozen_string_literal: true

version = File.read(File.join(File.dirname(__FILE__), "../JAT_VERSION")).strip
local_file = File.join(File.dirname(__FILE__), "../jat-#{version}.gem")
local_file_exist = File.file?(local_file)

require "bundler/inline"

gemfile(true, quiet: true) do
  source "https://rubygems.org"
  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "jat", "~> #{version}", local_file_exist ? {path: File.dirname(local_file)} : {}
end
