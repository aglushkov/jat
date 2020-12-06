# frozen_string_literal: true

module N1
  class User < ActiveRecord::Base
    has_many :comments
    has_many :albums
    has_many :images
  end
end
