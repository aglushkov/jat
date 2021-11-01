# frozen_string_literal: true

version = File.read(File.join(File.dirname(__FILE__), "../../JAT_VERSION")).strip
local_file = File.join(File.dirname(__FILE__), "../../jat-#{version}.gem")
local_file_exist = File.file?(local_file)

require "bundler/inline"

gemfile(true, quiet: true) do
  source "https://rubygems.org"
  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "jat", "~> #{version}", local_file_exist ? {path: File.dirname(local_file)} : {}
end

class SimpleSerializer < Jat
  plugin :simple_api
end

class UserSerializer < SimpleSerializer
  root :data
  config[:exposed] = :default # Default value can be omitted. Other options: :all, :none

  # Attributes are exposed by default
  attribute :id
  attribute :name

  # Hide attribute
  attribute :email, exposed: false

  # Relationships are hidden by default
  relationship :profile, serializer: -> { ProfileSerializer }

  # Expose relationship
  relationship :avatar, serializer: -> { AvatarSerializer }, exposed: true

  meta(:foo) { "bat" }
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
