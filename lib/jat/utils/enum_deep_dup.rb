# frozen_string_literal: true

class Jat
  # Duplicates nested enumerable data
  class EnumDeepDup
    DUP = {
      Hash => ->(data) { dup_hash_values(data) },
      Array => ->(data) { dup_array_values(data) }
    }.freeze

    def self.call(data)
      duplicate_data = data.dup
      DUP.fetch(duplicate_data.class).call(duplicate_data)
      duplicate_data
    end

    def self.dup_hash_values(duplicate_data)
      duplicate_data.each do |key, value|
        duplicate_data[key] = call(value) if value.is_a?(Enumerable)
      end
    end

    def self.dup_array_values(duplicate_data)
      duplicate_data.each_with_index do |value, index|
        duplicate_data[index] = call(value) if value.is_a?(Enumerable)
      end
    end
  end
end
