# frozen_string_literal: true

class Jat
  class CheckKey
    module ClassMethods
      ALLOWED_OPTS = %i[key delegate serializer includes many exposed]

      # @param params [Hash] new key params, includes :name, :opts, :block keys
      def call(params)
        check_name(params)
        check_opts(params)
        check_block(params)
      end

      private

      def check_name(params)
        check_is_string(params[:name], 'name')
        json_api_check_name(params)
      end

      def json_api_check_name(name:, opts:, **)
        name = name.to_sym
        return if (name != :type) && (name != :id)

        key_type = opts.key?(:serializer) ? 'Relationship' : 'Attribute'
        error("#{key_type} can't have `#{name}` name")
      end

      def check_opts(params)
        check_opts_key(params)
        check_opts_delegate(params)
        check_opts_serializer(params)
        check_opts_includes(params)
        check_opts_many(params)
        check_opts_exposed(params)

        check_opts_extra_keys(params[:opts])
      end

      def check_block(params)
        block = params[:block]
        return unless block

        block.parameters.each_with_index do |(param_type, _), index|
          next if (index < 2) && ((param_type == :opt) || (param_type == :req))

          error 'Block can include 1 or 2 args, no keywords or splat args'
        end
      end

      def check_opts_key(name:, opts:, block:)
        return unless opts.key?(:key)

        check_is_string(opts[:key], 'opts[:key]')
        check_opts_key_and_block_together(name: name, opts: opts, block: block)
      end

      def check_opts_key_and_block_together(name:, opts:, block:)
        return if !block || (opts[:key].to_sym == name.to_sym)

        error 'opts[:key] must be omitted when block provided, it will do nothing'
      end

      def check_opts_delegate(opts:, **)
        check_is_boolean(opts[:delegate], 'opts[:delegate]') if opts.key?(:delegate)
      end

      def check_opts_exposed(opts:, **)
        check_is_boolean(opts[:exposed], 'opts[:exposed]') if opts.key?(:exposed)
      end

      def check_opts_serializer(opts:, **)
        check_opts_serializer_type(opts)
        check_opts_serializer_with_many(opts)
      end

      def check_opts_serializer_type(opts)
        return unless opts.key?(:serializer)

        value = opts[:serializer]
        return if value.is_a?(Class) && (value < Jat)

        if value.is_a?(Proc)
          error 'Invalid opts[:serializer] proc, must be no params' if value.parameters.any?
        else
          error "Invalid opts[:serializer] param, must be callable or a subclass of Jat, but #{value} was given"
        end
      end

      def check_opts_serializer_proc
      end

      def check_opts_serializer_with_many(opts)
        return unless opts.key?(:many)
        return if opts.key?(:serializer)

        error 'opts[:many] must be provided only together with opts[:serializer]'
      end

      def check_opts_many(opts:, **)
        opt_many = opts.key?(:many)
        return unless opt_many

        check_is_boolean(opts[:many], 'opts[:many]')
      end

      # `includes` for relations must be simple Symbol or String. It is
      # converted to hash `{ include => {} }` so we can add nested includes to it later.
      #
      # Non-relation's `includes` can be any Array or Hash value, we don't
      # need to include anything nested inside it.
      def check_opts_includes(opts:, **)
        return unless opts.key?(:includes)
        value = opts[:includes]
        opt_name = 'opts[:includes]'

        if opts[:serializer]
          return if !value || value.empty?

          check_is_string(value, opt_name)
        else
          check_is_simple_object(value, opt_name)
        end
      end

      # Simple object consists of symbols, strings, arrays, hashes with symbol or string keys
      def check_is_simple_object(value, opt_name)
        case value
        when Symbol, String
        when Hash
          value.each do |key, val|
            invalid_includes_error(opt_name) if !key.is_a?(Symbol) && !key.is_a?(String)
            check_is_simple_object(val, opt_name)
          end
        when Array
          value.each { |val| check_is_simple_object(val, opt_name) }
        else
          invalid_includes_error(opt_name)
        end
      end

      def check_is_boolean(value, opt_name)
        return if value.is_a?(TrueClass) || value.is_a?(FalseClass)

        error("#{opt_name} must be Boolean, but #{value.inspect} was given")
      end

      def check_is_string(value, opt_name)
        return if value.is_a?(String) || value.is_a?(Symbol)

        error("#{opt_name} must be Symbol or String, but #{value.inspect} was given")
      end

      def invalid_includes_error(opt_name)
        error("Invalid #{opt_name} param, can be a simple Hash, Array, String, Symbol")
      end

      def check_opts_extra_keys(opts)
        given_opts = opts.keys
        extra_opts = given_opts - ALLOWED_OPTS

        return if extra_opts.size.zero?

        error("Extra opts #{extra_opts.inspect} were provided. Allowed opts: #{ALLOWED_OPTS.inspect}")
      end

      def error(error_message)
        raise Jat::Error, error_message
      end
    end

    extend(ClassMethods)
  end
end
