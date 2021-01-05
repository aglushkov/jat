# frozen_string_literal: true

class Jat
  # Freezes nested enumerable data
  class EnumDeepFreeze
    FREEZES = {
      Hash => ->(data) { data.each_value(&FREEZE_ENUMS) },
      Array => ->(data) { data.each(&FREEZE_ENUMS) }
    }.freeze

    FREEZE_ENUMS = ->(value) { call(value) if value.is_a?(Enumerable) }

    def self.call(data)
      data.freeze
      FREEZES.fetch(data.class).call(data)
      data
    end
  end
end
