# frozen_string_literal: true

class Jat
  module Plugins
    module BaseLowerCamelCase
      def self.plugin_name
        :base_lower_camel_case
      end

      def self.load(jat_class, **_opts)
        jat_class::Attribute.include(AttributeInstanceMethods)
      end

      module AttributeInstanceMethods
        def serialized_name
          LowerCamelCaseTransformation.call(name)
        end
      end
    end

    register_plugin(BaseLowerCamelCase.plugin_name, BaseLowerCamelCase)
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
