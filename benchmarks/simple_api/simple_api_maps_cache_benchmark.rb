# frozen_string_literal: true

version = File.read(File.join(File.dirname(__FILE__), "../../JAT_VERSION")).strip
local_file = File.join(File.dirname(__FILE__), "../../jat-#{version}.gem")
local_file_exist = File.file?(local_file)

require "bundler/inline"

gemfile(true, quiet: true) do
  source "https://rubygems.org"
  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "jat", "~> #{version}", local_file_exist ? {path: File.dirname(local_file)} : {}
  gem "benchmark-ips"
end

require "benchmark/ips"

### Serializers without cache

class SimpleSerializer < Jat
  plugin :simple_api
end

class UserSerializer < SimpleSerializer
  root :users

  attribute :id
  attribute(:name) { |user| [user.first_name, user.last_name].join(" ") }

  relationship :profile, serializer: -> { ProfileSerializer }, exposed: true
  relationship :roles, serializer: -> { RoleSerializer }, exposed: true
end

class ProfileSerializer < SimpleSerializer
  attribute :id
  attribute(:location) { |profile| profile.location || "Gotham City" }
  attribute :followers_count
end

class RoleSerializer < SimpleSerializer
  attribute :id
  attribute :name
end

### Serializers with cache

class SimpleSerializerCache < Jat
  plugin :simple_api
  plugin :simple_api_maps_cache
end

class UserSerializerCache < SimpleSerializerCache
  root :users

  attribute :id
  attribute(:name) { |user| [user.first_name, user.last_name].join(" ") }

  relationship :profile, serializer: -> { ProfileSerializer }, exposed: true
  relationship :roles, serializer: -> { RoleSerializer }, exposed: true
end

class ProfileSerializerCache < SimpleSerializerCache
  attribute :id
  attribute(:location) { |profile| profile.location || "Gotham City" }
  attribute :followers_count
end

class RoleSerializerCache < SimpleSerializerCache
  attribute :id
  attribute :name
end

require "ostruct"
role1 = OpenStruct.new(id: 4, name: "superhero")
role2 = OpenStruct.new(id: 3, name: "reporter")
profile = OpenStruct.new(id: 2, followers_count: 999, location: nil)
user = OpenStruct.new(id: 1, first_name: "Clark", last_name: "Kent", profile: profile, roles: [role1, role2])

Benchmark.ips do |x|
  x.config(time: 1, warmup: 0.1)

  x.report("Exclude Internal Cache") { UserSerializer.to_h(user) }
  x.report("Include Internal Cache") { UserSerializerCache.to_h(user) }

  x.compare!
end
