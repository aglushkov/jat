# frozen_string_literal: true

module N1
  class UserSerializer < Jat
    config.auto_preload = true
    config.exposed = :all

    type :user

    attribute :id
    relationship :images, serializer: -> { N1::ImageSerializer }
    relationship :comments, serializer: -> { N1::CommentSerializer }
    relationship :albums, serializer: -> { N1::AlbumSerializer }
  end
end
