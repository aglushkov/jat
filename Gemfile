# frozen_string_literal: true

source "https://rubygems.org"

gemspec

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

group :test do
  gem "m", "~> 1.5", ">= 1.5.1", require: false
  gem "debug", ">= 1.0.0"

  # General testing helpers
  gem "minitest", "~> 5.14"
  gem "mocha", "~> 1.12"
  gem "rake", "~> 13.0"

  # Code standard
  gem "simplecov", "~> 0.21"
  gem "standard", "1.5"

  # ORM plugins
  ruby_version = Gem::Version.new(RUBY_VERSION)
  ar_version =
    if ruby_version >= Gem::Version.new("3.0")
      "~> 7.0"
    elsif ruby_version >= Gem::Version.new("2.5")
      "~> 6.0"
    else
      "~> 5.2"
    end

  gem "activerecord", ar_version
  gem "sqlite3", platforms: [:ruby]
  gem "activerecord-jdbcsqlite3-adapter", platforms: [:jruby]
end
