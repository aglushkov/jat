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
      attributes = types_attrs[serializer.type][:attributes]

      attributes.each do |attr|
        includes = serializer.attrs[attr].includes
        next unless include?(includes)

        add_includes(result, includes)
      end
    end

    def add_relationships(result, serializer)
      relationships = types_attrs[serializer.type][:relationships]

      relationships.each do |attr|
        opts = serializer.attrs[attr]
        includes = opts.includes
        next unless include?(includes)

        add_nested_includes(result, includes, opts)
      end
    end

    def add_nested_includes(result, includes, opts)
      add_includes(result, includes)

      # nested includes can have only one key
      nested_result = result.fetch(includes.keys.first)
      nested_serializer = opts.serializer

      append(nested_result, nested_serializer)
    end

    def add_includes(res, includes)
      res.merge!(includes) do |_key, current_value, new_value|
        current_value.merge(new_value)
      end
    end

    def include?(includes)
      includes&.any?
    end
  end
end
