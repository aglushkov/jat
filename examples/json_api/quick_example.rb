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
  attribute(:name) { |user| [user.first_name, user.last_name].join(" ") }

  relationship :profile, serializer: -> { ProfileSerializer }, exposed: true
  relationship :roles, serializer: -> { RoleSerializer }, exposed: true
end

class ProfileSerializer < JsonapiSerializer
  type :profile

  attribute :id
  attribute(:location) { |profile| profile.location || "Gotham City" }
  attribute :followers_count
end

class RoleSerializer < JsonapiSerializer
  type :role

  attribute :id
  attribute :name
end

require "ostruct"
role1 = OpenStruct.new(id: 4, name: "superhero")
role2 = OpenStruct.new(id: 3, name: "reporter")
profile = OpenStruct.new(id: 2, followers_count: 999, location: nil)
user = OpenStruct.new(id: 1, first_name: "Clark", last_name: "Kent", profile: profile, roles: [role1, role2])

response = UserSerializer.to_h(user)

require "json"
puts JSON.pretty_generate(response)
