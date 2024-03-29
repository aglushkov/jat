# frozen_string_literal: true

version = File.read(File.join(File.dirname(__FILE__), "../../JAT_VERSION")).strip
local_file = File.join(File.dirname(__FILE__), "../../jat-#{version}.gem")
local_file_exist = File.file?(local_file)

require "bundler/inline"

gemfile(true, quiet: true) do
  source "https://rubygems.org"
  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "jat", "~> #{version}", local_file_exist ? {path: File.dirname(local_file)} : {}
  gem "sqlite3"
  gem "activerecord"
end

require "active_record"
require "logger"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.logger.level = Logger::INFO

# Schema (user has many posts, post has many comments)
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :first_name
    t.string :last_name
  end

  create_table :posts, force: true do |t|
    t.integer :user_id
    t.string :text
  end

  create_table :comments, force: true do |t|
    t.integer :post_id
    t.integer :user_id
    t.string :text
  end
end

# Models
class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user, optional: true
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :post, optional: true
  belongs_to :user, optional: true
end

# Data
user1 = User.create!(first_name: "Bruce", last_name: "Wayne")
user2 = User.create!(first_name: "Clark", last_name: "Kent")
user3 = User.create!(first_name: "Jane", last_name: "Doe")

post1 = Post.create!(user: user1, text: "post1")
post2 = Post.create!(user: user1, text: "post2")

Comment.create!(user: user1, post: post1, text: "comment1")
Comment.create!(user: user2, post: post1, text: "comment2")
Comment.create!(user: user3, post: post2, text: "comment3")
Comment.create!(user: user1, post: post2, text: "comment4")

# Serializers
class JsonapiSerializer < Jat
  plugin :json_api
  plugin :activerecord_preloads
end

class UserSerializer < JsonapiSerializer
  type :user

  attribute :first_name
  attribute :last_name

  relationship :posts, serializer: -> { PostSerializer }, exposed: true
end

class PostSerializer < JsonapiSerializer
  type :post

  attribute :text

  relationship :comments, serializer: -> { CommentSerializer }, exposed: true
end

class CommentSerializer < JsonapiSerializer
  type :comment

  attribute :text

  relationship :user, serializer: -> { UserSerializer }, exposed: false
end

# We need to show just DB queries in this examples to show we have no N+1
UserSerializer.extend(
  Module.new do
    def to_h(*)
      old_level = ActiveRecord::Base.logger.level
      ActiveRecord::Base.logger.level = Logger::DEBUG
      super
    ensure
      ActiveRecord::Base.logger.level = old_level
    end
  end
)

def example(message)
  puts
  puts "----------------"
  puts
  puts message
  puts
  yield
end

example("Single object:") do
  UserSerializer.to_h(user1.reload)
end

example("Single object with created post:") do
  user1.reload
  user1.posts.create!(text: "post3")

  UserSerializer.to_h(user1)
end

example("Array:") do
  users = [user1.reload, user2.reload, user3.reload]
  UserSerializer.to_h(users)
end

example("Array with created posts in some user:") do
  users = [user1.reload, user2.reload, user3.reload]
  user1.posts.create!(text: "post4")

  UserSerializer.to_h(users)
end

example("Relation:") do
  users = User.all
  UserSerializer.to_h(users)
end

example("Loaded Relation:") do
  users = User.all.load
  UserSerializer.to_h(users)
end

example("Relation included posts:") do
  users = User.all.includes(:posts)
  UserSerializer.to_h(users)
end

example("Loaded relation included posts:") do
  users = User.all.includes(:posts).load
  UserSerializer.to_h(users)
end
