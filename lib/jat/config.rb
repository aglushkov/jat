# frozen_string_literal: true

require 'jat/json'

class Jat
  class Config
    ALLOWED_OPTIONS = {
      delegate: { default: true, allowed: [true, false] },
      exposed: { default: :default, allowed: %i[all none default] },
      key_transform: { default: :none, allowed: %i[none camelLower] },
      meta: { callable_default: -> { {} } },
      to_str: { default: proc { |data, _context| Jat::JSON.dump(data) } }
    }.freeze

    def initialize(serializer)
      @serializer = serializer
      @config = ALLOWED_OPTIONS.transform_values do |value|
        value[:default] || value.fetch(:callable_default).()
      end
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

    # :reek:TooManyStatements
    def copy_to(subclass)
      subconfig = self.class.new(subclass)

      subconfig.delegate = delegate
      subconfig.exposed = exposed
      subconfig.key_transform = key_transform
      subconfig.meta = meta.dup
      subconfig.to_str = to_str

      subclass.config = subconfig
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
