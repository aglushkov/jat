# frozen_string_literal: true

require 'json'

class Jat
  class Config
    ALLOWED_OPTIONS = {
      to_json: { default: ->(hash) { JSON.dump(hash) } },
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

        allowed = data[:allowed]
        if allowed && !allowed.include?(value)
          raise Jat::Error, "#{key.capitalize} option can be only #{allowed}, #{value.inspect} was given"
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
