# frozen_string_literal: true

module N1
  class ResourceImage < ActiveRecord::Base
    belongs_to :resource, polymorphic: true
    belongs_to :image
  end
end
