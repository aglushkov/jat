# frozen_string_literal: true

class Jat
  class Validate
    module ClassMethods
      def call(key, opts, block)
        validate_key(key)
        validate_opts(opts)
        validate_block(block)

        validate_all(key, opts, block)
      end

      private

      def validate_key(value)
        validate_is_string(value, 'key')
      end

      def validate_opts(opts)
        validate_key_opts(opts[:key]) if opts.key?(:key)
        validate_delegate_opts(opts[:delegate]) if opts.key?(:delegate)
        validate_relationship_opts(opts[:relationship]) if opts.key?(:relationship)
        validate_includes_opts(opts) if opts.key?(:include)
      end

      def validate_block(block)
        return unless block

        block.parameters.each_with_index do |(param_type, _), index|
          next if (index < 2) && ((param_type == :opt) || (param_type == :req))

          error 'Invalid block params, can include up to 2 args (obj, params (optional)), no keyword or splat args'
        end
      end

      def validate_key_opts(value)
        validate_is_string(value, 'opts[:key]')
      end

      def validate_delegate_opts(value)
        validate_is_boolean(value, 'opts[:delegate]')
      end

      def validate_relationship_opts(value)
        validate_is_boolean(value, 'opts[:relationship]')
      end

      def validate_includes_opts(opts)
        includes = opts[:include]
        if opts[:relationship]
          validate_includes_for_relationship_opts(includes)
        else
          validate_includes_for_attribute_opts(includes)
        end
      end

      # Relationship's `include` must be simple Symbol or String. It is
      # converted to hash `{ include => {} }` so we can add nested includes to it later.
      def validate_includes_for_relationship_opts(value)
        validate_is_string(value, 'opts[:include]')
      end

      # Attribute's `include` can be any String, Array or Hash value, we don't
      # need to include anything nested inside it.
      def validate_includes_for_attribute_opts(value)
        case value
        when Symbol, String
        when Hash
          value.each do |key, val|
            invalid_attribute_include_error if !key.is_a?(Symbol) && !key.is_a?(String)
            validate_attribute_includes_opts(val)
          end
        when Array
          value.each { |val| validate_attribute_includes_opts(val) }
        else
          invalid_attribute_include_error
        end
      end

      def validate_all(key, opts, block)
        validate_all_opts_key(key, opts[:key], block)
      end

      def validate_all_opts_key(key, value, block)
        return if !value || !block || (value.to_sym == key.to_sym)

        error 'opts[:key] must be omitted when block provided, it will do nothing'
      end

      def validate_is_boolean(value, name)
        return if value.is_a?(TrueClass) || value.is_a?(FalseClass)

        error("#{name} must be Boolean, but #{value.class} was given")
      end

      def validate_is_string(value, name)
        return if value.is_a?(String) || value.is_a?(Symbol)

        error("#{name} must be Symbol or String, but #{value.class} was given")
      end

      def invalid_attribute_include_error
        error 'Invalid :include param, cannot include anything except Symbol, String, Hash, Array'
      end

      def error(message)
        raise Jat::Error, message
      end
    end

    extend(ClassMethods)
  end
end
