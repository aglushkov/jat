# frozen_string_literal: true

RSpec.describe 'Auto Preloads without N+1' do
  before do
    require 'active_record'
    require 'sqlite3'
    require 'rspec-sqlimit'
    Dir['./spec/features/n1/app/**/*.rb'].sort.each { |f| require f }

    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Schema.define do
      create_table :users

      create_table :comments do |t|
        t.belongs_to :user, index: false
      end

      create_table :albums do |t|
        t.belongs_to :user, index: false
      end

      create_table :images do |t|
        t.belongs_to :user, index: false
        t.string :src
      end

      create_table :resource_images do |t|
        t.belongs_to :resource, polymorphic: true, index: false
        t.belongs_to :image, index: false
      end
    end
  end

  context 'with active record relation' do
    before do
      2.times do
        user = N1::User.create!

        comment1 = N1::Comment.create!(user: user)
        comment2 = N1::Comment.create!(user: user)

        album1 = N1::Album.create!(user: user)
        album2 = N1::Album.create!(user: user)

        image1 = N1::Image.create!(user: user)
        image2 = N1::Image.create!(user: user)

        N1::ResourceImage.create(resource: comment1, image: image1)
        N1::ResourceImage.create(resource: comment2, image: image2)

        N1::ResourceImage.create(resource: album1, image: image1)
        N1::ResourceImage.create(resource: album1, image: image2)

        N1::ResourceImage.create(resource: album2, image: image1)
        N1::ResourceImage.create(resource: album2, image: image2)
      end
    end

    it 'returns all resources without N+1' do
      # Allowed Queries:
      # 1 - users
      # 2 - users images
      # 3 - users comments
      # 4 - users comments resource_images
      # 5 - users comments resource_images images
      # 6 - users albums
      # 7 - users albums resource_images
      # 8 - users albums resource_images images
      result = nil
      expect { result = N1::UserSerializer.to_h(N1::User.all) }.not_to exceed_query_limit(8)
      expect(result[:data].count).to eq 2 # users
      expect(result[:included].count).to eq 24 # other records
    end
  end

  context 'with array' do
    before do
      2.times do
        user = N1::User.create!

        comment1 = N1::Comment.create!(user: user)
        comment2 = N1::Comment.create!(user: user)

        album1 = N1::Album.create!(user: user)
        album2 = N1::Album.create!(user: user)

        image1 = N1::Image.create!(user: user)
        image2 = N1::Image.create!(user: user)

        N1::ResourceImage.create(resource: comment1, image: image1)
        N1::ResourceImage.create(resource: comment2, image: image2)

        N1::ResourceImage.create(resource: album1, image: image1)
        N1::ResourceImage.create(resource: album1, image: image2)

        N1::ResourceImage.create(resource: album2, image: image1)
        N1::ResourceImage.create(resource: album2, image: image2)
      end
    end

    it 'returns all resources without N+1' do
      # Allowed Queries:
      # 1 - users images
      # 2 - users comments
      # 3 - users comments resource_images
      # 4 - users comments resource_images images
      # 5 - users albums
      # 6 - users albums resource_images
      # 7 - users albums resource_images images
      users = N1::User.all.to_a
      result = nil
      expect { result = N1::UserSerializer.to_h(users) }.not_to exceed_query_limit(7)
      expect(result[:data].count).to eq 2 # users
      expect(result[:included].count).to eq 24 # other records
    end
  end

  context 'with one activerecord object' do
    before do
      user = N1::User.create!

      comment1 = N1::Comment.create!(user: user)
      comment2 = N1::Comment.create!(user: user)

      album1 = N1::Album.create!(user: user)
      album2 = N1::Album.create!(user: user)

      image1 = N1::Image.create!(user: user)
      image2 = N1::Image.create!(user: user)

      N1::ResourceImage.create(resource: comment1, image: image1)
      N1::ResourceImage.create(resource: comment2, image: image2)

      N1::ResourceImage.create(resource: album1, image: image1)
      N1::ResourceImage.create(resource: album1, image: image2)

      N1::ResourceImage.create(resource: album2, image: image1)
      N1::ResourceImage.create(resource: album2, image: image2)
    end

    it 'returns all resources without N+1' do
      # Allowed Queries:
      # 1 - users images
      # 2 - users comments
      # 3 - users comments resource_images
      # 4 - users comments resource_images images
      # 5 - users albums
      # 6 - users albums resource_images
      # 7 - users albums resource_images images
      result = nil
      user = N1::User.first
      expect { result = N1::UserSerializer.to_h(user) }.not_to exceed_query_limit(7)
      expect(result[:data][:id]).to eq user.id # user
      expect(result[:included].count).to eq 12 # other records
    end
  end
end
