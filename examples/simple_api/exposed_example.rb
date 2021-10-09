# frozen_string_literal: true

require_relative "../load_gem"

class SimpleSerializer < Jat
  plugin :simple_api
end

class UserSerializer < SimpleSerializer
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
