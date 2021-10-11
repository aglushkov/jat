# frozen_string_literal: true

module TestPlugin
  def self.before_load(jat_class, *)
    jat_class.config[:before_load] = jat_class.foo
  end

  def self.load(jat_class, **_opts)
    jat_class.extend(ClassMethods)
    jat_class.include(InstanceMethods)
    jat_class::Attribute.extend(AttributeClassMethods)
    jat_class::Attribute.include(AttributeMethods)
    jat_class::Config.extend(ConfigClassMethods)
    jat_class::Config.include(ConfigMethods)
  end

  def self.after_load(jat_class, *)
    jat_class.config[:after_load] = jat_class.foo
  end

  module ClassMethods
    def foo
      :plugin_foo
    end
  end

  module InstanceMethods
    def foo
      :plugin_foo
    end
  end

  module AttributeClassMethods
    def foo
      :plugin_foo
    end
  end

  module AttributeMethods
    def foo
      :plugin_foo
    end
  end

  module ConfigClassMethods
    def foo
      :plugin_foo
    end
  end

  module ConfigMethods
    def foo
      :plugin_foo
    end
  end
end
