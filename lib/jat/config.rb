# frozen_string_literal: true

require 'jat/json'

class Jat
  class Config
    DEFAULT_OPTS = {
      auto_preload: true,
      exposed: :default,
      key_transform: :none,
      meta: {}
    }.freeze

    module InstanceMethods
      attr_reader :opts

      def initialize(opts = {})
        @opts = deep_dup(DEFAULT_OPTS.merge(opts))
      end

      def auto_preload
        opts.fetch(:auto_preload)
      end

      def auto_preload=(value)
        check_value_allowed(:auto_preload, value, [true, false])
        opts[:auto_preload] = value
      end

      def exposed
        opts.fetch(:exposed)
      end

      def exposed=(value)
        check_value_allowed(:exposed, value, %i[all none default])
        old_value = exposed
        opts[:exposed] = value
        self.class.jat_class.refresh if old_value != value
      end

      def key_transform
        opts.fetch(:key_transform)
      end

      def key_transform=(value)
        check_value_allowed(:key_transform, value, %i[none camelLower])
        old_value = key_transform
        opts[:key_transform] = value
        self.class.jat_class.refresh if old_value != value
      end

      def meta
        opts.fetch(:meta)
      end

      def meta=(value)
        opts[:meta] = value
      end

      def to_str
        opts[:to_str] || proc { |data, _context| Jat::JSON.dump(data) }
      end

      def to_str=(value)
        opts[:to_str] = value
      end

      def opts_copy
        deep_dup(opts)
      end

      private

      # :reek:FeatureEnvy
      def check_value_allowed(key, value, allowed_values)
        return if allowed_values.include?(value)

        list = allowed_values.join(', ')
        raise Jat::Error, "#{key.capitalize} option can be only #{list} (#{value.inspect} was given)"
      end

      # Deep duplicates a nested hash of options.
      # :reek:FeatureEnvy
      def deep_dup(collection)
        duplicate_collection = collection.dup

        if duplicate_collection.is_a?(Hash)
          duplicate_collection.each do |key, value|
            duplicate_collection[key] = deep_dup(value) if value.is_a?(Enumerable)
          end
        end

        duplicate_collection
      end
    end

    module ClassMethods
      # Returns the Jat class that this config class is namespaced under.
      # :reek:Attribute
      attr_accessor :jat_class

      # Since Config is anonymously subclassed when Jat is subclassed,
      # and then assigned to a constant of the Jat subclass, make inspect
      # reflect the likely name for the class.
      def inspect
        "#{jat_class.inspect}::Config"
      end
    end

    include InstanceMethods
    extend ClassMethods
  end
end
