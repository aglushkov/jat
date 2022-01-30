# frozen_string_literal: true

class Jat
  #
  # Freezes nested enumerable data
  #
  class EnumDeepFreeze
    FREEZES = {
      Hash => ->(data) { data.each_value(&FREEZE_ENUMS) },
      Array => ->(data) { data.each(&FREEZE_ENUMS) }
    }.freeze
    private_constant :FREEZES

    FREEZE_ENUMS = ->(value) { call(value) if value.is_a?(Enumerable) }
    private_constant :FREEZE_ENUMS

    #
    # Deeply freezes provided data
    #
    # @param data [Hash, Array] Data to freeze
    #
    # @return [Hash, Array] Provided data, that was deeply frozen
    #
    def self.call(data)
      data.freeze
      FREEZES.fetch(data.class).call(data)
      data
    end
  end
end
