# frozen_string_literal: true

module Preloads
  class Image < ActiveRecord::Base
    belongs_to :user
    has_many :resource_images
  end
end
