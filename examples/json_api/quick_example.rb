# frozen_string_literal: true

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"
  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem 'jat', '~> 0.0.3'
end

class JsonapiSerializer < Jat
  plugin :json_api, activerecord: false # or true to preload relations automatically
end

class UserSerializer < JsonapiSerializer
  type :user

  attribute :id
  attribute(:name) { |user| [user.first_name, user.last_name].join(' ') }

  attribute :profile, serializer: -> { ProfileSerializer }, exposed: true
  attribute :roles, serializer: -> { RoleSerializer }, exposed: true
end

class ProfileSerializer < JsonapiSerializer
  type :profile

  attribute :id
  attribute(:location) { |profile| profile.location || 'Gotham City' }
  attribute :followers_count
end

class RoleSerializer < JsonapiSerializer
  type :role

  attribute :id
  attribute :name
end

require 'ostruct'
role1 = OpenStruct.new(id: 4, name: 'superhero')
role2 = OpenStruct.new(id: 3, name: 'reporter')
profile = OpenStruct.new(id: 2, followers_count: 999, location: nil)
user = OpenStruct.new(id: 1, first_name: 'Clark', last_name: 'Kent', profile: profile, roles: [role1, role2])

response = UserSerializer.to_h(user)

require 'json'
puts JSON.pretty_generate(response)
