# frozen_string_literal: true

require "bundler/inline"

gemfile(true, quiet: true) do
  source "https://rubygems.org"
  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "jat", "~> 0.0.3"
end

class SimpleSerializer < Jat
  plugin :simple_api
end

class UserSerializer < SimpleSerializer
  config[:exposed] = :default # Default value can be omitted. Other options: :all, :none

  # Attributes are exposed by default
  attribute :name

  # Hide exposed by default attribute
  attribute :email, exposed: false

  # Relationships are hidden by default
  attribute :profile, serializer: -> { ProfileSerializer }

  # Expose hidden by default relationship
  attribute :avatar, serializer: -> { AvatarSerializer }, exposed: true
end

class AvatarSerializer < SimpleSerializer
  attribute :url
  attribute :url_2x
end

class ProfileSerializer < SimpleSerializer
  attribute :id
end

require "ostruct"
avatar = OpenStruct.new(url: "http://example.com/url", url_2x: "http://example.com/url_2x")
profile = OpenStruct.new(id: 2)
user = OpenStruct.new(id: 1, name: "batman", avatar: avatar, email: "janedoe@example.com", profile: profile)

require "json"

puts "UserSerializer.to_h(user, exposed: :default)"
puts JSON.pretty_generate(UserSerializer.to_h(user, exposed: :default))

puts

puts "UserSerializer.to_h(user, exposed: :all)"
puts JSON.pretty_generate(UserSerializer.to_h(user, exposed: :all))

puts

puts "UserSerializer.to_h(user, exposed: :none, params: { fields: 'name,email' })"
puts JSON.pretty_generate(UserSerializer.to_h(user, exposed: :none, params: {fields: "name,email"}))
