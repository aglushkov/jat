# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'jat'
  s.version     = '0.0.1'
  s.date        = '2020-12-07'
  s.summary     = 'JSON API Serializer'
  s.description = <<~DESC
    Serialization tool to build JSON API response
  DESC
  s.authors     = ['aglushkov']
  s.email       = 'aglushkov@shakuro.com'
  s.files       = ['lib/jat.rb']
  s.homepage    = 'https://github.com/aglushkov/jat'
  s.license     = 'MIT'
  s.required_ruby_version = 2.5
end
