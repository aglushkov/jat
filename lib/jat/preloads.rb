# frozen_string_literal: true

class Jat
  class Preloads
    attr_reader :initial_result

    def initialize(types_attrs)
      @types_attrs = types_attrs
      @initial_result = {}
    end

    def for(serializer)
      @initial_result = {}
      append(initial_result, serializer)
      initial_result
    rescue SystemStackError
      raise Error, "Stack level too deep, recursive preloads detected: #{initial_result}"
    end

    private

    attr_reader :types_attrs

    def append(result, serializer)
      attrs = types_attrs[serializer.type]
      attributes_names = attrs[:attributes] + attrs[:relationships]

      add_attributes(result, serializer, attributes_names)
    end

    def add_attributes(result, serializer, attributes_names)
      attributes_names.each do |name|
        attribute = serializer.attributes[name]
        preloads = attribute.preloads
        next unless preloads # we should not addd preloads and nested preloads when nil provided

        add_preloads(result, preloads, attribute)
      end
    end

    def add_preloads(result, preloads, attribute)
      unless preloads.empty?
        preloads = deep_dup(preloads)
        merge(result, preloads)
      end

      add_nested_preloads(result, attribute) if attribute.relation?
    end

    def add_nested_preloads(result, attribute)
      path = attribute.preloads_path
      nested_result = nested(result, path)
      nested_serializer = attribute.serializer

      append(nested_result, nested_serializer.())
    end

    def merge(result, preloads)
      result.merge!(preloads) do |_key, value_one, value_two|
        merge(value_one, value_two)
      end
    end

    def deep_dup(preloads)
      preloads.dup.transform_values! do |nested_preloads|
        deep_dup(nested_preloads)
      end
    end

    def nested(result, path)
      !path || path.empty? ? result : result.dig(*path)
    end
  end
end
