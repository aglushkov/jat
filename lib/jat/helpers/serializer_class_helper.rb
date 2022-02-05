# frozen_string_literal: true

class Jat
  module Helpers
    # Stores link to current serializer class
    module SerializerClassHelper
      # @return [Class<Jat>] Serializer class that current class is namespaced under.
      attr_accessor :serializer_class
    end
  end
end
