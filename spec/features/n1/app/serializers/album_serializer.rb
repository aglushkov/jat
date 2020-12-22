# frozen_string_literal: true

module N1
  class AlbumSerializer < Jat
    config.auto_preload = true
    config.exposed = :all

    type :album

    attribute :id
    relationship :images,
                 key: :resource_images,
                 serializer: -> { N1::ResourceImageSerializer },
                 preload: { resource_images!: :image }
  end
end
