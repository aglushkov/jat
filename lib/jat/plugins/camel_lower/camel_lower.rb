# frozen_string_literal: true

class Jat
  module Plugins
    module CamelLower
      module AttributeMethods
        def name
          first_word, *other = original_name.to_s.split("_")
          last_words = other.map!(&:capitalize).join

          :"#{first_word}#{last_words}"
        end
      end
    end

    register_plugin(:camel_lower, CamelLower)
  end
end
