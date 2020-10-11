# frozen_string_literal: true

class Jat
  class CheckAttribute
    attr_reader :name, :opts, :block

    ALLOWED_OPTS = %i[key delegate serializer includes many exposed].freeze
    NAME_REGEXP = /\A[-a-zA-Z0-9_]+\z/

    def initialize(name, opts, block)
      @name = name.is_a?(String) ? name.to_sym : name
      @opts = opts
      @block = block
    end

    def validate
      check_name
      check_opts
      check_block
    end

    private

    def check_name
      check_is_string(name, 'name')
      check_is_reserved
      check_is_valid_name
    end

    def check_is_reserved
      return if (name != :type) && (name != :id)

      key_type = opts.key?(:serializer) ? 'Relationship' : 'Attribute'
      error("#{key_type} can't have `#{name}` name")
    end

    def check_is_valid_name
      if '-_'.include?(name[0]) || '-_'.include?(name[-1])
        error "Name must not start or end with '-' or '_'"
      end

      return if NAME_REGEXP.match?(name)

      error "Name can include only a-z, A-Z, 0-9, '-' and '_'"
    end


    def check_opts
      check_opts_key
      check_opts_delegate
      check_opts_serializer
      check_opts_includes
      check_opts_many
      check_opts_exposed

      check_opts_extra_keys
    end

    def check_block
      return unless block

      block.parameters.each_with_index do |(param_type, _), index|
        next if (index < 2) && ((param_type == :opt) || (param_type == :req))

        error 'Block can include 1 or 2 args, no keywords or splat args'
      end
    end

    def check_opts_key
      return unless opts.key?(:key)

      check_is_string(opts[:key], 'opts[:key]')
      check_opts_key_and_block_together
    end

    def check_opts_key_and_block_together
      return if !block || (opts[:key].to_sym == name)

      error 'opts[:key] must be omitted when block provided, it will do nothing'
    end

    def check_opts_delegate
      check_is_boolean(opts[:delegate], 'opts[:delegate]') if opts.key?(:delegate)
    end

    def check_opts_exposed
      check_is_boolean(opts[:exposed], 'opts[:exposed]') if opts.key?(:exposed)
    end

    def check_opts_serializer
      check_opts_serializer_type
      check_opts_serializer_with_many
    end

    def check_opts_serializer_type
      return unless opts.key?(:serializer)

      value = opts[:serializer]
      return if value.is_a?(Class) && (value < Jat)

      if value.is_a?(Proc)
        error 'Invalid opts[:serializer] proc, must be no params' if value.parameters.any?
      else
        error "Invalid opts[:serializer] param, must be callable or a subclass of Jat, but #{value} was given"
      end
    end

    def check_opts_serializer_with_many
      return unless opts.key?(:many)
      return if opts.key?(:serializer)

      error 'opts[:many] must be provided only together with opts[:serializer]'
    end

    def check_opts_many
      opt_many = opts.key?(:many)
      return unless opt_many

      check_is_boolean(opts[:many], 'opts[:many]')
    end

    # `includes` for relations must be simple Symbol or String. It is
    # converted to hash `{ include => {} }` so we can add nested includes to it later.
    #
    # Non-relation's `includes` can be any Array or Hash value, we don't
    # need to include anything nested inside it.
    def check_opts_includes
      return unless opts.key?(:includes)

      value = opts[:includes]
      return if !value || value.empty?

      check = opts[:serializer] ? :check_is_string : :check_includes_is_simple_object
      __send__(check, value, 'opts[:includes]')
    end

    # Simple object consists of symbols, strings, arrays, hashes with symbol or string keys
    def check_includes_is_simple_object(value, opt_name)
      case value
      when Symbol, String then nil
      when Hash then check_includes_hash(value, opt_name)
      when Array then check_includes_array(value, opt_name)
      else
        invalid_includes_error(opt_name)
      end
    end

    def check_includes_hash(value, opt_name)
      value.each do |key, val|
        invalid_includes_error(opt_name) if !key.is_a?(Symbol) && !key.is_a?(String)
        check_includes_is_simple_object(val, opt_name)
      end
    end

    def check_includes_array(value, opt_name)
      value.each { |val| check_includes_is_simple_object(val, opt_name) }
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

    def check_opts_extra_keys
      given_opts = opts.keys
      extra_opts = given_opts - ALLOWED_OPTS

      return if extra_opts.size.zero?

      error("Extra opts #{extra_opts.inspect} were provided. Allowed opts: #{ALLOWED_OPTS.inspect}")
    end

    def error(error_message)
      raise Jat::Error, error_message
    end
  end
end
