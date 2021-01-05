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
            # Reset associations that will be preloaded to fix possible bugs with
            # ActiveRecord::Associations::Preloader
            preloads.each_key { |key| object.association(key).reset }
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
            objects.preload(preloads)
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
            objects.all? { |object| object.instance_of?(first_object_class) }
          end
        end

        extend ClassMethods
      end
    end
  end
end
