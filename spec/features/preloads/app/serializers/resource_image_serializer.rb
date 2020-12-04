# frozen_string_literal: true

module Preloads
  class ResourceImageSerializer < Jat
    config.auto_preload = true
    type :resource_image

    attribute :image_src do |resource_image|
      resource_image.image.src
    end
  end
end
