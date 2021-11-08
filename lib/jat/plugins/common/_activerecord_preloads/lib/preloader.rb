# frozen_string_literal: true

class Jat
  module Plugins
    module ActiverecordPreloads
      class Preloader
        module ClassMethods
          def preload(object, preloads)
            preload_handler = handlers.find { |handler| handler.fit?(object) }
            raise Error, "Can't preload #{preloads.inspect} to #{object.inspect}" unless preload_handler

            preload_handler.preload(object, preloads)
          end

          def handlers
            @handlers ||= [ActiverecordRelation, ActiverecordObject, ActiverecordArray].freeze
          end
        end

        extend ClassMethods
      end

      class ActiverecordObject
        module ClassMethods
          def fit?(object)
            object.is_a?(ActiveRecord::Base)
          end

          def preload(object, preloads)
            ActiveRecord::Associations::Preloader.new.preload(object, preloads)
            object
          end
        end

        extend ClassMethods
      end

      class ActiverecordRelation
        module ClassMethods
          def fit?(objects)
            objects.is_a?(ActiveRecord::Relation)
          end

          def preload(objects, preloads)
            if objects.loaded?
              array_objects = objects.to_a
              ActiverecordArray.preload(array_objects, preloads)
              objects
            else
              objects.preload(preloads).load
            end
          end
        end

        extend ClassMethods
      end

      class ActiverecordArray
        module ClassMethods
          def fit?(objects)
            objects.is_a?(Array) &&
              ActiverecordObject.fit?(objects.first) &&
              same_kind?(objects)
          end

          def preload(objects, preloads)
            ActiveRecord::Associations::Preloader.new.preload(objects, preloads)
            objects
          end

          private

          def same_kind?(objects)
            first_object_class = objects.first.class
            objects.all? { |object| object.instance_of?(first_object_class) }
          end
        end

        extend ClassMethods
      end
    end
  end
end
