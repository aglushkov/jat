# frozen_string_literal: true

require "bundler/inline"

gemfile(true, quiet: true) do
  source "https://rubygems.org"
  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "jat", "~> 0.0.3"
end

class JsonapiSerializer < Jat
  plugin :json_api
end

class UserSerializer < JsonapiSerializer
  config[:exposed] = :default # Default value can be omitted. Other options: :all, :none

  type :user
  attribute :id

  # Attributes are exposed by default
  attribute :name

  # Hide exposed by default attribute
  attribute :email, exposed: false

  # Relationships are hidden by default
  relationship :profile, serializer: -> { ProfileSerializer }

  # Expose hidden by default relationship
  relationship :avatar, serializer: -> { AvatarSerializer }, exposed: true
end

class AvatarSerializer < JsonapiSerializer
  config[:exposed] = :none
  type :avatar

  attribute :id, exposed: true
  attribute :url, exposed: true
  attribute :url_2x
end

class ProfileSerializer < JsonapiSerializer
  type :profile
  attribute :id
end

require "ostruct"
avatar = OpenStruct.new(id: 3, url: "http://example.com/url", url_2x: "http://example.com/url_2x")
profile = OpenStruct.new(id: 2)
user = OpenStruct.new(id: 1, name: "batman", avatar: avatar, email: "janedoe@example.com", profile: profile)

require "json"

puts "UserSerializer.to_h(user, exposed: :default)"
puts JSON.pretty_generate(UserSerializer.to_h(user, exposed: :default))

puts

puts "UserSerializer.to_h(user, exposed: :all)"
puts JSON.pretty_generate(UserSerializer.to_h(user, exposed: :all))

puts

puts "UserSerializer.to_h(user, exposed: :none, params: { fields: { user: 'name,email' }})"
puts JSON.pretty_generate(UserSerializer.to_h(user, exposed: :none, params: {fields: {user: "name,email"}}))
