# frozen_string_literal: true

require "test_helper"

describe Jat::Plugins do
  let(:described_module) { Jat::Plugins }

  describe ".register_plugin" do
    it "adds plugin to the @plugins list" do
      plugin = Module.new
      plugin_name = :new_plugin
      described_module.register_plugin(plugin_name, plugin)

      assert_equal plugin, described_module.instance_variable_get(:@plugins).fetch(plugin_name)
    end
  end

  describe ".find_plugin" do
    it "returns module if module provided" do
      plugin = Module.new
      assert_equal plugin, described_module.find_plugin(plugin)
    end

    it "returns already registered plugin found by name" do
      plugin = Module.new
      plugin_name = :new_plugin
      described_module.register_plugin(plugin_name, plugin)

      assert_equal plugin, described_module.find_plugin(plugin_name)
    end

    it "returns global plugins found by name" do
      assert_equal "Jat::Plugins::Activerecord", described_module.find_plugin(:activerecord).name
      assert_equal "Jat::Plugins::Cache", described_module.find_plugin(:cache).name
      assert_equal "Jat::Plugins::JsonApi", described_module.find_plugin(:json_api).name
      assert_equal "Jat::Plugins::LowerCamelCase", described_module.find_plugin(:lower_camel_case).name
      assert_equal "Jat::Plugins::MapsCache", described_module.find_plugin(:maps_cache).name
      assert_equal "Jat::Plugins::Preloads", described_module.find_plugin(:preloads).name
      assert_equal "Jat::Plugins::Presenter", described_module.find_plugin(:presenter).name
      assert_equal "Jat::Plugins::SimpleApi", described_module.find_plugin(:simple_api).name
      assert_equal "Jat::Plugins::ToStr", described_module.find_plugin(:to_str).name
      assert_equal "Jat::Plugins::Types", described_module.find_plugin(:types).name
      assert_equal "Jat::Plugins::ValidateParams", described_module.find_plugin(:validate_params).name
    end

    it "returns json_api only plugins found by name (name has `json_api_` prefix)" do
      assert_equal "Jat::Plugins::JsonApiActiverecord", described_module.find_plugin(:json_api_activerecord).name
      assert_equal "Jat::Plugins::JsonApiLowerCamelCase", described_module.find_plugin(:json_api_lower_camel_case).name
      assert_equal "Jat::Plugins::JsonApiMapsCache", described_module.find_plugin(:json_api_maps_cache).name
      assert_equal "Jat::Plugins::JsonApiPreloads", described_module.find_plugin(:json_api_preloads).name
      assert_equal "Jat::Plugins::JsonApiValidateParams", described_module.find_plugin(:json_api_validate_params).name
    end

    it "returns simple_api only plugins found by name (name has `simple_api_` prefix)" do
      assert_equal "Jat::Plugins::SimpleApiActiverecord", described_module.find_plugin(:simple_api_activerecord).name
      assert_equal "Jat::Plugins::SimpleApiLowerCamelCase", described_module.find_plugin(:simple_api_lower_camel_case).name
      assert_equal "Jat::Plugins::SimpleApiMapsCache", described_module.find_plugin(:simple_api_maps_cache).name
      assert_equal "Jat::Plugins::SimpleApiPreloads", described_module.find_plugin(:simple_api_preloads).name
      assert_equal "Jat::Plugins::SimpleApiValidateParams", described_module.find_plugin(:simple_api_validate_params).name
    end

    it "returns base plugins found by name (name has `base_` prefix)" do
      assert_equal "Jat::Plugins::BaseActiverecordPreloads", described_module.find_plugin(:base_activerecord_preloads).name
      assert_equal "Jat::Plugins::BaseLowerCamelCase", described_module.find_plugin(:base_lower_camel_case).name
      assert_equal "Jat::Plugins::BasePreloads", described_module.find_plugin(:base_preloads).name
    end

    it "raises specific error if plugin not found" do
      err = assert_raises(Jat::PluginLoadError) { described_module.find_plugin(:foo) }
      assert_equal "Plugin 'foo' does not exist", err.message
    end

    it "raises specific error if plugin was found by name but was not registered" do
      plugin_name = "test_foo"

      # Add plugin folder and file in plugins directory
      plugin_dir = File.join(__dir__, "../../../lib/jat/plugins", plugin_name)
      plugin_path = File.join(plugin_dir, "#{plugin_name}.rb")
      Dir.mkdir(plugin_dir)
      File.new(plugin_path, File::CREAT)

      err = assert_raises(Jat::PluginLoadError) { described_module.find_plugin(plugin_name) }
      assert_equal "Plugin '#{plugin_name}' did not register itself correctly", err.message
    ensure
      File.unlink(plugin_path)
      Dir.unlink(plugin_dir)
    end
  end
end
