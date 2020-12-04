# frozen_string_literal: true

module Preloads
  class UserSerializer < Jat
    config.auto_preload = true
    type :user

    relationship :images,
                 serializer: -> { Preloads::ImageSerializer },
                 includes: :images,
                 exposed: true

    relationship :comments,
                 serializer: -> { Preloads::CommentSerializer },
                 includes: :comments,
                 exposed: true

    relationship :albums,
                 serializer: -> { Preloads::AlbumSerializer },
                 includes: :albums,
                 exposed: true
  end
end
