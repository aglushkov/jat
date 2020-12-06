# frozen_string_literal: true

class Jat
  class PreloadHandler
    class ActiveRecordObject
      class << self
        def fit?(object)
          object.is_a?(ActiveRecord::Base)
        end

        def preload(object, preloads)
          # Reset associations that will be preloaded to fix possible bugs with
          # ActiveRecord::Associations::Preloader
          preloads.each_key { |key| object.association(key).reset }
          ActiveRecord::Associations::Preloader.new.preload(object, preloads)

          object
        end
      end
    end
  end
end
