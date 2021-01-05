# frozen_string_literal: true

Gem::Specification.new do |gem|
  gem.name = "jat"
  gem.version = "0.0.2"
  gem.date = "2020-12-07"
  gem.summary = "JSON Serializer"
  gem.description = <<~DESC
    The serializer allows you to generate a response based on the fields requested by the client.
    Besides, it avoids manually adding includes and solves N+1 problems on its own.
  DESC

  gem.authors = ["Andrey Glushkov"]
  gem.email = "aglushkov@shakuro.com"
  gem.files = Dir["README.md", "LICENSE.txt", "CHANGELOG.md", "lib/**/*.rb", "jat.gemspec", "doc/**/*.md"]
  gem.test_files = `git ls-files -- test/*`.split("\n")
  gem.homepage = "https://github.com/aglushkov/jat"
  gem.license = "MIT"
  gem.required_ruby_version = 2.5
  gem.metadata     = {
    "bug_tracker_uri" => "https://github.com/aglushkov/jat/issues",
    "changelog_uri" => "https://github.com/aglushkov/jat/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/aglushkov/jat",
  }

  # General testing helpers
  gem.add_development_dependency "minitest", "~> 5.14"
  gem.add_development_dependency "mocha", "~> 1.12"
  gem.add_development_dependency "rake", "~> 13.0"

  # Code standard
  gem.add_development_dependency "standard", "~> 1.0"
  gem.add_development_dependency "simplecov", "~> 0.21"

  # ORM plugins
  gem.add_development_dependency "activerecord", RUBY_VERSION >= "2.5" ? "~> 6.0" : "~> 5.2"
  gem.add_development_dependency "sqlite3", "~> 1.4" unless RUBY_ENGINE == "jruby"
end
