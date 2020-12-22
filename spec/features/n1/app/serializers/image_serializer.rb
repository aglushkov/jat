# frozen_string_literal: true

module N1
  class ImageSerializer < Jat
    type :image

    attribute :id
    attribute :src
  end
end
