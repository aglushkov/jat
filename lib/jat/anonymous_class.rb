# frozen_string_literal: true

class Jat
  #
  # Stores common methods of anonymous classes we define, such as:
  #  - MySerializer::Attribute
  #  - MySerializer::Config
  #  - etc.
  #
  module AnonymousClass
    # @return [Jat] Serializer class that current class is namespaced under.
    attr_accessor :jat_class
  end
end
