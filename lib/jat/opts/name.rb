# frozen_string_literal: true

class Jat
  class Opts
    class Name
      TRANSFORMATIONS = {
        none: :none,
        camelLower: :camel_lower
      }.freeze

      class << self
        def call(original_name, transform)
          method_name = TRANSFORMATIONS.fetch(transform)
          __send__(method_name, original_name)
        end

        private

        def none(string)
          string
        end

        def camel_lower(string)
          first_word, *other = string.to_s.split('_')
          last_words = other.map!(&:capitalize).join

          "#{first_word}#{last_words}".to_sym
        end
      end
    end
  end
end
