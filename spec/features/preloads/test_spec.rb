# frozen_string_literal: true

RSpec.describe 'Auto Preloads' do
  before do
    require 'active_record'
    require 'sqlite3'
    require 'rspec-sqlimit'
    Dir['./spec/features/preloads/app/**/*.rb'].sort.each { |f| require f }

    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

    ActiveRecord::Migration.verbose = false
    ActiveRecord::Schema.define do
      create_table :users do |t|
      end

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
      ActiveRecord::Base.transaction do # speedup, use single transaction
        2.times do
          user = Preloads::User.create!

          comment1 = Preloads::Comment.create!(user: user)
          comment2 = Preloads::Comment.create!(user: user)

          album1 = Preloads::Album.create!(user: user)
          album2 = Preloads::Album.create!(user: user)

          image1 = Preloads::Image.create!(user: user)
          image2 = Preloads::Image.create!(user: user)

          Preloads::ResourceImage.create(resource: comment1, image: image1)
          Preloads::ResourceImage.create(resource: comment2, image: image2)

          Preloads::ResourceImage.create(resource: album1, image: image1)
          Preloads::ResourceImage.create(resource: album1, image: image2)

          Preloads::ResourceImage.create(resource: album2, image: image1)
          Preloads::ResourceImage.create(resource: album2, image: image2)
        end
      end
    end

    it 'returns all resources without N+1' do
      # Allowed Queries:
      # 1 - users
      # 2 - users comments
      # 3 - users albums
      # 4 - users images
      # 5 - users comments resource_images
      # 6 - users comments resource_images images
      # 7 - users albums resource_images
      # 8 - users albums resource_images images
      result = nil
      expect { result = Preloads::UserSerializer.to_h(Preloads::User.all) }.not_to exceed_query_limit(8)
      expect(result[:data].count).to eq 2 # users
      expect(result[:included].count).to eq 24 # other records
    end
  end

  context 'with array' do
    before do
      ActiveRecord::Base.transaction do # speedup, use single transaction
        2.times do
          user = Preloads::User.create!

          comment1 = Preloads::Comment.create!(user: user)
          comment2 = Preloads::Comment.create!(user: user)

          album1 = Preloads::Album.create!(user: user)
          album2 = Preloads::Album.create!(user: user)

          image1 = Preloads::Image.create!(user: user)
          image2 = Preloads::Image.create!(user: user)

          Preloads::ResourceImage.create(resource: comment1, image: image1)
          Preloads::ResourceImage.create(resource: comment2, image: image2)

          Preloads::ResourceImage.create(resource: album1, image: image1)
          Preloads::ResourceImage.create(resource: album1, image: image2)

          Preloads::ResourceImage.create(resource: album2, image: image1)
          Preloads::ResourceImage.create(resource: album2, image: image2)
        end
      end
    end

    it 'returns all resources without N+1' do
      # Allowed Queries:
      # 1 - users comments
      # 2 - users albums
      # 3 - users images
      # 4 - users comments resource_images
      # 5 - users comments resource_images images
      # 6 - users albums resource_images
      # 7 - users albums resource_images images
      users = Preloads::User.all.to_a
      result = nil
      expect { result = Preloads::UserSerializer.to_h(users) }.not_to exceed_query_limit(7)
      expect(result[:data].count).to eq 2 # users
      expect(result[:included].count).to eq 24 # other records
    end
  end

  context 'with one activerecord object' do
    before do
      ActiveRecord::Base.transaction do # speedup, use single transaction
        user = Preloads::User.create!

        comment1 = Preloads::Comment.create!(user: user)
        comment2 = Preloads::Comment.create!(user: user)

        album1 = Preloads::Album.create!(user: user)
        album2 = Preloads::Album.create!(user: user)

        image1 = Preloads::Image.create!(user: user)
        image2 = Preloads::Image.create!(user: user)

        Preloads::ResourceImage.create(resource: comment1, image: image1)
        Preloads::ResourceImage.create(resource: comment2, image: image2)

        Preloads::ResourceImage.create(resource: album1, image: image1)
        Preloads::ResourceImage.create(resource: album1, image: image2)

        Preloads::ResourceImage.create(resource: album2, image: image1)
        Preloads::ResourceImage.create(resource: album2, image: image2)
      end
    end

    it 'returns all resources without N+1' do
      # Allowed Queries:
      # 1 - users comments
      # 2 - users albums
      # 3 - users images
      # 4 - users comments resource_images
      # 5 - users comments resource_images images
      # 6 - users albums resource_images
      # 7 - users albums resource_images images
      result = nil
      user = Preloads::User.first
      expect { result = Preloads::UserSerializer.to_h(user) }.not_to exceed_query_limit(7)
      expect(result[:data][:id]).to eq user.id # user
      expect(result[:included].count).to eq 12 # other records
    end
  end
end
