# frozen_string_literal: true

require "test_helper"
require "test_plugin"

describe "plugin system" do
  describe "Jat.plugin" do
    let(:jat_class) { Class.new(Jat) }
    let(:components) { [jat_class, jat_class::Attribute, jat_class::Config] }

    before do
      components.each do |component|
        component::InstanceMethods.send(:define_method, :foo) { :foo }
        component::ClassMethods.send(:define_method, :foo) { :foo }
      end
    end

    after do
      components.each do |component|
        component::InstanceMethods.send(:undef_method, :foo)
        component::ClassMethods.send(:undef_method, :foo)
      end
    end

    it "allows the plugin to override base methods of core classes" do
      components.each do |component|
        assert_equal :foo, component.foo
        assert_equal :foo, component.allocate.foo
      end

      jat_class.plugin(TestPlugin)

      components.each do |component|
        assert_equal :plugin_foo, component.foo
        assert_equal :plugin_foo, component.allocate.foo
      end
    end

    it "calls before_load before loading plugin" do
      jat_class.plugin(TestPlugin)
      assert_equal :foo, jat_class.config[:before_load]
    end

    it "calls after_load after loading plugin" do
      jat_class.plugin(TestPlugin)
      assert_equal :plugin_foo, jat_class.config[:after_load]
    end
  end
end
