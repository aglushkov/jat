# frozen_string_literal: true

module N1
  class Comment < ActiveRecord::Base
    belongs_to :user
    has_many :resource_images, as: :resource
    has_many :images, through: :resource_images
  end
end
