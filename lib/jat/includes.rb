# frozen_string_literal: true

class Jat
  class Includes
    def initialize(types_attrs)
      @types_attrs = types_attrs
    end

    def for(serializer)
      result = {}
      append(result, serializer)
      result
    end

    private

    attr_reader :types_attrs

    def append(result, serializer)
      add_attributes(result, serializer)
      add_relationships(result, serializer)
    end

    def add_attributes(result, serializer)
      attributes_names = types_attrs[serializer.type][:attributes]

      attributes_names.each do |name|
        attribute = serializer.attributes[name]
        add_attribute(result, attribute)
      end
    end

    def add_attribute(result, attribute)
      includes = attribute.includes
      return unless include?(includes)

      add_includes(result, includes)
    end

    def add_relationships(result, serializer)
      relationships_names = types_attrs[serializer.type][:relationships]

      relationships_names.each do |name|
        attribute = serializer.attributes[name]
        add_relationship(result, attribute)
      end
    end

    def add_relationship(result, attribute)
      includes = attribute.includes
      return unless include?(includes)

      add_nested_includes(result, includes, attribute)
    end

    def add_nested_includes(result, includes, attribute)
      add_includes(result, includes)

      nested_result = deep_nested_result(result, includes)
      nested_serializer = attribute.serializer

      append(nested_result, nested_serializer.())
    end

    def add_includes(res, includes)
      res.merge!(includes) do |_key, current_value, new_value|
        current_value.merge(new_value)
      end
    end

    def deep_nested_result(result, includes, cross_refs = [])
      check_cross_refs(cross_refs, result)

      key, nested_includes = includes.to_a.first
      result = result.fetch(key)
      return result if nested_includes.empty?

      deep_nested_result(result, nested_includes, cross_refs)
    end

    # :reek:FeatureEnvy
    def check_cross_refs(cross_refs, current_result)
      raise Error, "Cross referenced includes #{cross_refs}" if cross_refs.include?(current_result)

      cross_refs << current_result
    end

    def include?(includes)
      includes&.any?
    end
  end
end
