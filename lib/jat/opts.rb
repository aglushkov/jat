# frozen_string_literal: true

require 'jat/opts/check'

class Jat
  class Opts
    attr_reader :current_serializer, :original_name, :opts, :original_block

    def initialize(current_serializer, params)
      Check.(params)

      @current_serializer = current_serializer
      @original_name = params.fetch(:name).to_sym

      @opts = params.fetch(:opts).freeze
      @original_block = params.fetch(:block)
    end

    def key
      opts.key?(:key) ? opts[:key].to_sym : original_name
    end

    def name
      case current_serializer.config.key_transform
      when :camel_lower then camel_lower(original_name)
      else original_name
      end
    end

    def delegate?
      opts.fetch(:delegate, current_serializer.config.delegate)
    end

    def exposed?
      case current_serializer.config.exposed
      when :all then opts.fetch(:exposed, true)
      when :none then opts.fetch(:exposed, false)
      else opts.fetch(:exposed, !relation?)
      end
    end

    def many?
      opts.fetch(:many, false)
    end

    def relation?
      opts.key?(:serializer)
    end

    def serializer
      return unless relation?

      value = opts[:serializer]
      value.is_a?(Proc) ? proc_serializer(value) : value
    end

    def includes
      incl = relation? ? opts.fetch(:includes, key) : opts[:includes]
      Utils::IncludesToHash.(incl) if incl
    end

    def block
      return if !original_block && !delegate?

      original_block ? transform_original_block : delegate_block
    end

    def copy_to(subclass)
      self.class.new(subclass, name: name, opts: opts, block: original_block)
    end

    private

    def transform_original_block
      return original_block if original_block.parameters.count == 2

      block = original_block
      ->(obj, _params) { block.(obj) }
    end

    def delegate_block
      delegate_field = key
      ->(obj, _params) { obj.public_send(delegate_field) }
    end

    # :reek:FeatureEnvy
    def proc_serializer(value)
      lambda do
        serializer = value.()

        if !serializer.is_a?(Class) || !(serializer < Jat)
          raise Jat::Error, "Invalid serializer `#{serializer.inspect}`, must be a subclass of Jat"
        end

        serializer
      end
    end

    def camel_lower(string)
      first_word, *other = string.to_s.split('_')
      last_words = other.map!(&:capitalize).join

      "#{first_word}#{last_words}".to_sym
    end
  end
end
