RSpec.describe Jat do
  let(:jat) do
    Class.new(Jat)
  end

  def set_type
    jat.type(:type)
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
      set_type
      obj = Class.new { def new_id; 'ID'; end }.new
      expect(jat.new.id(obj)).to eq 'ID'
    end

    it 'allows to redefine #id by providing block' do
      jat.id { |_obj| 'ID' }
      set_type
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
  end

  describe '#id' do
    it 'delegates to objects #id method' do
      set_type
      obj = Class.new { def id; 'ID'; end }.new
      expect(jat.new.id(obj)).to eq 'ID'
    end
  end
end
