# frozen_string_literal: true

class Jat
  class Config
    ALLOWED_OPTIONS = {
      delegate: { default: true, allowed: [true, false] },
      exposed: { default: :default, allowed: %i[all none default] },
      key_transform: { default: :none, allowed: %i[none camel_lower] }
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

        unless data[:allowed].include?(value)
          raise Jat::Error, "#{key.capitalize} option can be only #{data[:allowed]}, #{value.inspect} was given"
        end

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
  end
end
