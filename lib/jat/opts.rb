# frozen_string_literal: true

require 'jat/opts/validate'
require 'jat/opts/name'
require 'jat/opts/includes_with_path'
require 'jat/opts/serializer'
require 'jat/opts/block'

class Jat
  class Opts
    attr_reader :current_serializer, :original_name, :opts, :original_block

    def initialize(current_serializer, params)
      Validate.(params)

      @current_serializer = current_serializer
      @original_name = params.fetch(:name).to_sym

      @opts = params.fetch(:opts).freeze
      @original_block = params.fetch(:block)
    end

    def key
      opts.key?(:key) ? opts[:key].to_sym : original_name
    end

    def name
      Name.(original_name, current_serializer.config.key_transform)
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
      Serializer.(opts[:serializer]) if relation?
    end

    # :reek:TooManyStatements
    def includes_with_path
      includes = relation? ? opts.fetch(:includes, key) : opts[:includes]
      return [{}, []] unless includes

      includes = Utils::IncludesToHash.(includes)
      return [includes, []] if includes.empty? || !relation?

      IncludesWithPath.(includes)
    end

    def block
      Block.(original_block, delegate?, key)
    end

    def copy_to(subclass)
      self.class.new(subclass, name: name, opts: opts, block: original_block)
    end
  end
end
