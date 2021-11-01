# frozen_string_literal: true

class Jat
  module Plugins
    module LowerCamelCase
      def self.load(jat_class, **_opts)
        jat_class::Attribute.include(AttributeInstanceMethods)
      end

      module AttributeInstanceMethods
        def name
          LowerCamelCaseTransformation.call(original_name)
        end
      end
    end

    register_plugin(:_lower_camel_case, LowerCamelCase)
  end

  class LowerCamelCaseTransformation
    SEPARATOR = "_"

    def self.call(string)
      first_word, *others = string.to_s.split(SEPARATOR)

      first_word[0] = first_word[0].downcase
      last_words = others.each(&:capitalize!).join

      :"#{first_word}#{last_words}"
    end
  end
end
