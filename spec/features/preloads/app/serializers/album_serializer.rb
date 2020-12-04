# frozen_string_literal: true

module Preloads
  class AlbumSerializer < Jat
    config.auto_preload = true
    type :album

    relationship :images,
                 key: :resource_images,
                 serializer: -> { Preloads::ResourceImageSerializer },
                 includes: { resource_images!: :image },
                 exposed: true
  end
end
