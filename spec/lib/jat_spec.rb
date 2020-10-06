# frozen_string_literal: true

RSpec.describe Jat do
  let(:jat) do
    Class.new(described_class)
  end

  describe '.type' do
    it 'does not allows to ask for type before type is defined' do
      expect { jat.type }.to raise_error Jat::Error, /has no defined type/
    end

    it 'saves and returns current type' do
      jat.type :users
      expect(jat.type).to eq :users
    end
  end

  describe '.id' do
    it 'prohibits to add key and block together' do
      expect { jat.id(key: :foo) { |_obj| 'ID' } }.to raise_error Jat::Error, /key.*block/i
    end

    it 'prohibits to call .id without key and block' do
      expect { jat.id }.to raise_error Jat::Error, /key.*block/i
    end

    it 'allows to redefine #id by providing other key' do
      jat.id(key: :new_id)
      jat.type :jat
      obj = Class.new { def new_id; 'ID'; end }.new
      expect(jat.new.id(obj)).to eq 'ID'
    end

    it 'allows to redefine #id by providing block' do
      jat.id { |_obj| 'ID' }
      jat.type :jat
      obj = Class.new
      expect(jat.new.id(obj)).to eq 'ID'
    end
  end


  describe '.attribute' do
    it 'does not allows to add attribute with `type` name' do
      expect { jat.attribute :type }.to raise_error Jat::Error, /Attribute can't have `type` name/
    end

    it 'does not allows to add attribute with `id` name' do
      expect { jat.attribute :id }.to raise_error Jat::Error, /Attribute can't have `id` name/
    end

    it 'adds attribute with default params' do
      jat.attribute :foo
      expect(jat.keys[:foo]).to eq(exposed: true, key: :foo)
    end

    it 'adds attribute with provided params' do
      jat.attribute :foo, exposed: false, key: :foobar
      expect(jat.keys[:foo]).to eq(exposed: false, key: :foobar)
    end

    it 'delegates attribute' do
      jat.type :jat
      jat.attribute :length
      expect(jat.new.length('word', nil)).to eq 4
    end

    it 'does not delegate attribute with { delegate: false } option' do
      jat.type :jat
      jat.attribute :length, delegate: false
      jat.define_method(:length) { |obj, _params| 33 }
      expect(jat.new.length('word', nil)).to eq 33
    end

    it 'allows to provide block' do
      jat.type :jat
      jat.attribute(:length) { |obj| obj.length * 2 }
      expect(jat.new.length('word', nil)).to eq 8
    end

    it 'allows to provide block with two params' do
      jat.type :jat
      jat.attribute(:length) { |obj, params| obj.length * params[:mod] }
      expect(jat.new.length('word', mod: 10)).to eq 40
    end

    it 'allows to redefine attribute' do
      jat.type :jat
      jat.attribute(:length) { |obj| obj.length * 2 }
      jat.attribute(:length) { |obj, params| obj.length / 2 + params[:mod] }
      expect(jat.new.length('word', mod: 100)).to eq 102
    end

    it 'sets `exposed: true` by default' do
      jat.attribute(:key)
      expect(jat.keys[:key][:exposed]).to eq true
    end

    it 'sets `exposed: false` when global option `exposed: :none` provided' do
      jat.options[:exposed] = :none
      jat.attribute(:key)

      expect(jat.keys[:key][:exposed]).to eq false
    end
  end

  describe '.relationship' do
    it 'does not allows to add relationship with `type` name' do
      expect { jat.relationship :type, serializer: nil }
        .to raise_error Jat::Error, /Relationship can't have `type` name/
    end

    it 'does not allows to add relationship with `id` name' do
      expect { jat.relationship :id, serializer: nil }
        .to raise_error Jat::Error, /Relationship can't have `id` name/
    end

    it 'adds relationship with default params' do
      ser = Class.new(Jat)
      jat.relationship :foo, serializer: ser
      expect(jat.keys[:foo]).to eq(
        exposed: false,
        key: :foo,
        many: false,
        serializer: ser,
        includes: { foo: {} }
      )
    end

    it 'adds relationship with provided params' do
      ser = Class.new(Jat)
      jat.relationship :foo, serializer: ser, exposed: true, many: true, key: :foobar, includes: :bazz
      expect(jat.keys[:foo]).to eq(
        serializer: ser,
        exposed: true,
        many: true,
        key: :foobar,
        includes: { bazz: {}}
      )
    end

    it 'sets `exposed: false` by default' do
      ser = Class.new(Jat)
      jat.relationship :key, serializer: ser

      expect(jat.keys[:key][:exposed]).to eq false
    end

    it 'sets `exposed: true` when global option `exposed: :all` provided' do
      ser = Class.new(Jat)
      jat.options[:exposed] = :all
      jat.relationship :key, serializer: ser

      expect(jat.keys[:key][:exposed]).to eq true
    end
  end

  describe '#id' do
    it 'delegates to objects #id method by default' do
      jat.type :jat
      obj = Class.new { def id; 'ID'; end }.new
      expect(jat.new.id(obj)).to eq 'ID'
    end
  end

  describe '#_includes' do
    it 'delegates to Jat::Include with correct params' do
      jat.type :jat
      serializer = jat.new
      allow(Jat::Includes).to receive(:call).with(jat, serializer._full_map).and_return('RES')

      expect(serializer._includes).to eq 'RES'
    end
  end
end
