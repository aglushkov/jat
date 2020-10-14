# frozen_string_literal: true

class Jat
  class Config
    DEFAULTS = {
      delegate: true, # false
      exposed: :default # all, none
    }.freeze
    DELEGATE_ALLOWED_VALUES = [true, false].freeze
    EXPOSED_ALLOWED_VALUES = %i[all none default].freeze

    def initialize(serializer, options = nil)
      @serializer = serializer
      @config = (options || DEFAULTS).dup
    end

    def delegate
      config.fetch(:delegate)
    end

    def exposed
      config.fetch(:exposed)
    end

    def delegate=(value)
      return if delegate == value

      unless DELEGATE_ALLOWED_VALUES.include?(value)
        raise Jat::Error, "Delegate option must be boolean, #{value.inspect} was given"
      end

      config[:delegate] = value
      serializer.refresh
    end

    def exposed=(value)
      return if exposed == value

      unless EXPOSED_ALLOWED_VALUES.include?(value)
        raise Jat::Error, "Exposed option can be only :all, :none, :default, #{value.inspect} was given"
      end

      config[:exposed] = value
      serializer.refresh
    end

    def copy_to(subclass)
      subclass.config = self.class.new(subclass, config)
    end

    private

    attr_reader :config, :serializer
  end
end
