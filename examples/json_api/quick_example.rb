# frozen_string_literal: true

require_relative "../load_gem"

class JsonapiSerializer < Jat
  plugin :json_api
end

class UserSerializer < JsonapiSerializer
  config[:exposed] = :default # Default value can be omitted. Other options: :all, :none

  type :user

  attribute(:name) { |user| [user.first_name, user.last_name].join(" ") }

  relationship :profile, serializer: -> { ProfileSerializer }, exposed: true
  relationship :roles, serializer: -> { RoleSerializer }, exposed: true
end

class ProfileSerializer < JsonapiSerializer
  type :profile

  attribute(:location) { |profile| profile.location || "Gotham City" }
  attribute :followers_count
end

class RoleSerializer < JsonapiSerializer
  type :role

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
