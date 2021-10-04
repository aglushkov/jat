# frozen_string_literal: true

class Jat
  module Plugins
    module CamelLower
      def self.apply(jat_class)
        jat_class::Attribute.include(AttributeInstanceMethods)
      end

      def self.after_apply(jat_class)
        jat_class.config[:camel_lower] = true
      end

      module AttributeInstanceMethods
        def name
          CamelLowerTransformation.call(original_name)
        end
      end
    end

    register_plugin(:camel_lower, CamelLower)
  end

  class CamelLowerTransformation
    SEPARATOR = "_"

    def self.call(string)
      first_word, *others = string.to_s.split(SEPARATOR)

      first_word[0] = first_word[0].downcase
      last_words = others.each(&:capitalize!).join

      :"#{first_word}#{last_words}"
    end
  end
end
