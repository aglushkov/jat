# frozen_string_literal: true

module Preloads
  class Album < ActiveRecord::Base
    belongs_to :user
    has_many :resource_images, as: :resource
    has_many :images, through: :resource_images
  end
end
