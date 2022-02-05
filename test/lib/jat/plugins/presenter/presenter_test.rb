# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::Presenter" do
  describe "before load" do
    it "raises error if no response plugin is loaded" do
      serializer_class = Class.new(Jat)
      err = assert_raises(Jat::Error) { serializer_class.plugin :presenter }
      assert_equal "Please load :json_api or :simple_api plugin first", err.message
    end
  end

  describe "ClassMethods" do
    let(:serializer_class) do
      serializer_class = Class.new(Jat)
      serializer_class.plugin :simple_api
      serializer_class.plugin :presenter
      serializer_class
    end

    let(:presenter_class) { serializer_class::Presenter }

    describe ".serializer_class=" do
      it "assigns @serializer_class" do
        presenter_class.serializer_class = :foo
        assert_equal :foo, presenter_class.instance_variable_get(:@serializer_class)
      end
    end

    describe ".serializer_class" do
      it "returns self @serializer_class" do
        assert_same serializer_class, presenter_class.instance_variable_get(:@serializer_class)
        assert_same serializer_class, presenter_class.serializer_class
      end
    end
  end

  describe "with simple_api" do
    let(:serializer) do
      Class.new(Jat) do |base|
        base.plugin :simple_api
        base.plugin :presenter
      end
    end

    describe ".inherited" do
      let(:parent) { serializer }

      it "inherits presenter class" do
        child = Class.new(parent)
        assert_equal parent::Presenter, child::Presenter.superclass
      end
    end

    it "adds presenter methods when adding attribute" do
      serializer.attribute :length
      assert_includes serializer::Presenter.instance_methods, :length
    end

    it "adds presenter methods when adding attribute with key" do
      serializer.attribute :length, key: :size
      assert_includes serializer::Presenter.instance_methods, :size
    end

    it "does not add presenter methods when adding attribute with block" do
      serializer.attribute(:length) {}
      refute_includes serializer::Presenter.instance_methods, :length
    end

    it "adds presenter methods used in block after first serialization" do
      serializer.attribute(:length) { |obj| obj.size }

      refute_includes serializer::Presenter.instance_methods, :size
      serializer.to_h("")
      assert_includes serializer::Presenter.instance_methods, :size
    end

    it "allows to use custom methods defined directly in Presenter class" do
      serializer::Presenter.class_exec do
        def rev
          reverse
        end
      end

      serializer.attribute(:rev) { |obj| obj.rev }
      rev = serializer.to_h("jingle")[:rev]
      assert_equal "elgnij", rev
    end

    it "allows to override attribute methods" do
      serializer.attribute :qrcode1
      serializer.attribute :qrcode2

      assert_includes serializer::Presenter.instance_methods, :qrcode1
      assert_includes serializer::Presenter.instance_methods, :qrcode2
      serializer::Presenter.class_exec do
        def qrcode1
          common
        end

        def qrcode2
          common
        end

        private

        def common
          @qrcode = "QRCODE"
        end
      end

      res = serializer.to_h(nil)
      qrcode1 = res[:qrcode1]
      qrcode2 = res[:qrcode2]
      assert_equal "QRCODE", qrcode1
      assert_equal "QRCODE", qrcode2
    end
  end

  describe "with json_api" do
    let(:serializer) do
      Class.new(Jat) do |base|
        base.plugin :json_api
        base.plugin :presenter
        base.type :test
        base.id { |obj| obj }
      end
    end

    describe ".inherited" do
      let(:parent) { serializer }

      it "inherits presenter class" do
        child = Class.new(parent)
        assert_equal parent::Presenter, child::Presenter.superclass
      end
    end

    it "adds presenter methods when adding attribute" do
      serializer.attribute :length
      assert_includes serializer::Presenter.instance_methods, :length
    end

    it "adds presenter methods when adding attribute with key" do
      serializer.attribute :length, key: :size
      assert_includes serializer::Presenter.instance_methods, :size
    end

    it "does not add presenter methods when adding attribute with block" do
      serializer.attribute(:length) {}
      refute_includes serializer::Presenter.instance_methods, :length
    end

    it "adds presenter methods used in block after first serialization" do
      serializer.attribute(:length) { |obj| obj.size }

      refute_includes serializer::Presenter.instance_methods, :size
      serializer.to_h("")
      assert_includes serializer::Presenter.instance_methods, :size
    end

    it "allows to use custom methods defined directly in Presenter class" do
      serializer::Presenter.class_exec do
        def rev
          reverse
        end
      end

      serializer.attribute(:rev) { |obj| obj.rev }
      rev = serializer.to_h("jingle")[:data][:attributes][:rev]
      assert_equal "elgnij", rev
    end

    it "allows to override attribute methods" do
      serializer.attribute :qrcode1
      serializer.attribute :qrcode2

      assert_includes serializer::Presenter.instance_methods, :qrcode1
      assert_includes serializer::Presenter.instance_methods, :qrcode2
      serializer::Presenter.class_exec do
        def qrcode1
          common
        end

        def qrcode2
          common
        end

        private

        def common
          @qrcode = "QRCODE"
        end
      end

      res = serializer.to_h(nil)[:data][:attributes]
      qrcode1 = res[:qrcode1]
      qrcode2 = res[:qrcode2]
      assert_equal "QRCODE", qrcode1
      assert_equal "QRCODE", qrcode2
    end
  end
end
