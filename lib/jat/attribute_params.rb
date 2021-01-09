# frozen_string_literal: true

require 'jat/attribute_params/name'
require 'jat/attribute_params/preloads_with_path'
require 'jat/attribute_params/serializer'

class Jat
  # Handles transformation of provided attribute params
  class AttributeParams
    attr_reader :jat_class, :original_name, :opts, :original_block

    def initialize(jat_class, params)
      @jat_class = jat_class
      @original_name = params.fetch(:name).to_sym

      @opts = params.fetch(:opts).freeze
      @original_block = params.fetch(:block)
    end

    def key
      opts.key?(:key) ? opts[:key].to_sym : original_name
    end

    def name
      Name.(original_name, config.key_transform)
    end

    def exposed?
      case config.exposed
      when :all then opts.fetch(:exposed, true)
      when :none then opts.fetch(:exposed, false)
      else opts.fetch(:exposed, !relation?)
      end
    end

    def many?
      opts[:many]
    end

    def relation?
      opts.key?(:serializer)
    end

    def serializer
      Serializer.(opts[:serializer]) if relation?
    end

    # :reek:TooManyStatements
    # :reek:NilCheck
    # rubocop:disable Metrics/CyclomaticComplexity
    def preloads_with_path
      return [nil, nil] unless config.auto_preload

      preloads = opts[:preload]

      # Return [nil, nil] when manually specified to include `nil` or `false`
      return [nil, nil] if opts.key?(:preload) && !preloads

      preloads ||= key if relation?
      preloads = Utils::PreloadsToHash.(preloads)
      return [preloads, nil] if preloads.empty? || !relation?

      PreloadsWithPath.(preloads)
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def block
      original_block || begin
        key_method_name = key
        -> { object.public_send(key_method_name) }
      end
    end

    private

    def config
      jat_class.config
    end
  end
end