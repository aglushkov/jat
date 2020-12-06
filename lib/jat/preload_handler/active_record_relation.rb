# frozen_string_literal: true

class Jat
  class PreloadHandler
    class ActiveRecordRelation
      class << self
        def fit?(objects)
          objects.is_a?(ActiveRecord::Relation)
        end

        def preload(objects, preloads)
          objects.preload(preloads)
        end
      end
    end
  end
end
