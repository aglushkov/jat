# frozen_string_literal: true

class Jat
  class PreloadHandler
    class ActiveRecordArray
      class << self
        def fit?(objects)
          objects.is_a?(Array) &&
            ActiveRecordObject.fit?(objects.first) &&
            same_kind?(objects)
        end

        def preload(objects, preloads)
          # Reset associations that will be preloaded to fix possible bugs with
          # ActiveRecord::Associations::Preloader
          preloads.each_key { |key| reset_association(objects, key) }
          ActiveRecord::Associations::Preloader.new.preload(objects, preloads)

          objects
        end

        private

        def reset_association(objects, key)
          objects.each { |object| object.association(key).reset }
        end

        def same_kind?(objects)
          first_object_class = objects.first.class
          objects.all? { |object| object.class == first_object_class }
        end
      end
    end
  end
end
