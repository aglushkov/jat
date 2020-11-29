# frozen_string_literal: true

class Jat
  class Includes
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
      raise Error, "Stack level too deep, recursive includes detected: #{initial_result}"
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
        add_attribute(result, attribute)

        add_nested_includes(result, attribute) if attribute.relation?
      end
    end

    def add_attribute(result, attribute)
      includes = attribute.includes
      return if includes.empty?

      includes = deep_dup(includes)
      merge(result, includes)
    end

    # :reek:FeatureEnvy (refers to 'attribute' more than self)
    def add_nested_includes(result, attribute)
      path = attribute.includes_path

      nested_result = path.empty? ? result : result.dig(*path)
      nested_serializer = attribute.serializer

      append(nested_result, nested_serializer.())
    end

    def merge(result, includes)
      result.merge!(includes) do |_key, value_one, value_two|
        merge(value_one, value_two)
      end
    end

    def deep_dup(includes)
      includes.dup.transform_values! do |nested_includes|
        deep_dup(nested_includes)
      end
    end
  end
end
