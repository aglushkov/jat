# frozen_string_literal: true

require 'jat/json'

class Jat
  class Config
    ALLOWED_OPTIONS = {
      to_str: { default: ->(data) { Jat::JSON.dump(data) } },
      delegate: { default: true, allowed: [true, false] },
      exposed: { default: :default, allowed: %i[all none default] },
      key_transform: { default: :none, allowed: %i[none camelLower] }
    }.freeze

    def initialize(serializer)
      @serializer = serializer
      @config = ALLOWED_OPTIONS.transform_values { |value| value[:default] }
    end

    ALLOWED_OPTIONS.each do |key, data|
      define_method(key) do
        config.fetch(key)
      end

      define_method("#{key}=") do |value|
        return if public_send(key) == value

        check_value_allowed(key, value, data[:allowed])

        config[key] = value
        serializer.refresh
      end
    end

    def copy_to(subclass)
      config = self.class.new(subclass)
      config.delegate = delegate
      config.exposed = exposed

      subclass.config = config
    end

    private

    attr_reader :config, :serializer

    # :reek:FeatureEnvy
    def check_value_allowed(key, value, allowed_values)
      return unless allowed_values
      return if allowed_values.include?(value)

      list = allowed_values.join(', ')
      raise Jat::Error, "#{key.capitalize} option can be only #{list} (#{value.inspect} was given)"
    end
  end
end
