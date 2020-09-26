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

  describe '.attribute' do
    it 'does not allows to add attribute with `type` name' do
      expect { jat.attribute :type }.to raise_error Jat::Error, /Attribute can't have `type` name/
    end

    it 'does not allows to add attribute with `id` name' do
      expect { jat.attribute :id }.to raise_error Jat::Error, /Attribute can't have `id` name/
    end

    it 'adds attribute with default params' do
      jat.attribute :foo
      expect(jat.keys[:foo]).to eq(exposed: true)
    end

    it 'adds attribute with provided params' do
      jat.attribute :foo, exposed: false, foo: :bar
      expect(jat.keys[:foo]).to eq(exposed: false, foo: :bar)
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
      jat.relationship :foo, serializer: nil
      expect(jat.keys[:foo]).to eq(exposed: false, serializer: nil, many: false, relationship: true)
    end

    it 'adds relationship with provided params' do
      jat.relationship :foo, serializer: nil, exposed: true, foo: :bar, many: true
      expect(jat.keys[:foo]).to eq(serializer: nil, exposed: true, foo: :bar, many: true, relationship: true)
    end

    it 'adds relationship even when requested to not' do
      jat.relationship :foo, serializer: nil, relationship: false
      expect(jat.keys[:foo]).to include(relationship: true)
    end
  end

  describe '#id' do
    it 'delegates to objects #id method' do
      set_type
      obj = Class.new { def id; 'ID'; end }.new
      expect(jat.new.id(obj)).to eq 'ID'
    end

    it 'allows to redefine #id by providing other field' do
      set_type
      jat.id(field: :new_id)
      obj = Class.new { def new_id; 'ID'; end }.new
      expect(jat.new.id(obj)).to eq 'ID'
    end

    it 'allows to redefine #id by providing block' do
      set_type
      jat.id { |_obj| 'ID' }
      obj = Class.new
      expect(jat.new.id(obj)).to eq 'ID'
    end
  end

  # describe '.serialize' do
  #   it 'calls serializer with default params' do
  #     allow(Jat::Plugins::JSON_API::Serializer).to receive(:call)

  #     described_class.serialize('OBJ', 'SER')

  #     expect(Jat::Plugins::JSON_API::Serializer)
  #       .to have_received(:call).with('OBJ', 'SER', many: false, meta: nil, params: nil)
  #   end

  #   it 'calls serializer with provided params' do
  #     allow(Jat::Plugins::JSON_API::Serializer).to receive(:call)

  #     described_class.serialize('OBJ', 'SER', many: 'MANY', meta: 'META', params: 'PARAMS')

  #     expect(Jat::Plugins::JSON_API::Serializer)
  #       .to have_received(:call).with('OBJ', 'SER', many: 'MANY', meta: 'META', params: 'PARAMS')
  #   end
  # end
end
