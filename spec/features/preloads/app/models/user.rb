# frozen_string_literal: true

module Preloads
  class User < ActiveRecord::Base
    has_many :comments
    has_many :albums
    has_many :images
  end
end
