# frozen_string_literal: true

module Preloads
  class CommentSerializer < Jat
    config.auto_preload = true
    type :comment

    relationship :images,
                 key: :resource_images,
                 serializer: -> { Preloads::ResourceImageSerializer },
                 includes: { resource_images!: :image },
                 exposed: true
  end
end
