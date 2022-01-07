# frozen_string_literal: true

Gem::Specification.new do |gem|
  gem.name = "jat"
  gem.version = File.read(File.join(File.dirname(__FILE__), "JAT_VERSION")).strip
  gem.summary = "JSON API TOOLKIT"
  gem.description = <<~DESC
    JAT serializer allows you to generate a JSON response based on the fields requested by the client.
    Besides, it helps to preload relations to avoid N+1 when used with activerecord.
  DESC

  gem.authors = ["Andrey Glushkov"]
  gem.email = "aglushkov@shakuro.com"
  gem.files = Dir["lib/**/*.rb"]
  gem.test_files = Dir["test/**/*.rb"]
  gem.homepage = "https://github.com/aglushkov/jat"
  gem.license = "MIT"
  gem.required_ruby_version = 2.5
  gem.metadata = {
    "bug_tracker_uri" => "https://github.com/aglushkov/jat/issues",
    "changelog_uri" => "https://github.com/aglushkov/jat/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/aglushkov/jat"
  }

  # General testing helpers
  gem.add_development_dependency "minitest", "~> 5.14"
  gem.add_development_dependency "mocha", "~> 1.12"
  gem.add_development_dependency "rake", "~> 13.0"

  # Code standard
  gem.add_development_dependency "simplecov", "~> 0.21"
  gem.add_development_dependency "standard", "~> 1.0"

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

  gem.add_development_dependency "activerecord", ar_version
  gem.add_development_dependency "sqlite3", "~> 1.4" unless RUBY_ENGINE == "jruby"
end
