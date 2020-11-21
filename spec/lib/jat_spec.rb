# frozen_string_literal: true

RSpec.describe Jat do
  let(:jat) do
    Class.new(described_class)
  end

  describe '.type' do
    it 'does not allows to ask for type before type is defined' do
      expect { jat.type }.to raise_error(Jat::Error, /has no defined type/)
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
    it 'adds attribute' do
      jat.attribute :foo
      expect(jat.attributes[:foo].relation?).to eq false
    end

    it 'allows to redefine attribute' do
      jat.attribute(:foo, delegate: true)
      expect(jat.attributes[:foo].delegate?).to eq true

      jat.attribute(:foo, delegate: false)
      expect(jat.attributes[:foo].delegate?).to eq false
    end
  end

  describe '.relationship' do
    it 'adds relationship' do
      jat.attribute :foo, serializer: jat
      expect(jat.attributes[:foo].serializer).to eq jat
    end

    it 'allows to redefine relationship' do
      jat.attribute(:foo, exposed: true, serializer: jat)
      expect(jat.attributes[:foo].exposed?).to eq true

      jat.attribute(:foo, exposed: false, serializer: jat)
      expect(jat.attributes[:foo].exposed?).to eq false
    end
  end

  describe '#id' do
    it 'delegates to objects #id method by default' do
      jat.type :jat
      obj = Class.new { def id; 'ID'; end }.new
      expect(jat.new.id(obj)).to eq 'ID'
    end
  end

  describe '.to_h' do
    it 'returns serialized to hash response' do
      opts = { params: { fields: { jat: 'first' } }, meta: { foo: :bar } }

      ser = instance_double(jat)
      allow(jat).to receive(:new).with(opts[:params]).and_return(ser)
      allow(ser).to receive(:to_h).with('OBJ', meta: { foo: :bar }).and_return('HASH')

      expect(jat.to_h('OBJ', opts)).to eq 'HASH'
    end
  end

  describe '.to_str' do
    it 'returns serialized to string response' do
      opts = { params: { fields: { jat: 'first' } }, meta: { foo: :bar } }

      ser = instance_double(jat)
      allow(jat).to receive(:new).with(opts[:params]).and_return(ser)
      allow(ser).to receive(:to_str).with('OBJ', meta: { foo: :bar }).and_return('STRING')

      expect(jat.to_str('OBJ', opts)).to eq 'STRING'
    end
  end

  describe '#to_h' do
    it 'returns serialized response' do
      jat.type :jat
      jat.id key: :itself

      result = jat.new.to_h('OBJECT', meta: { foo: :bar })
      expect(result).to eq(
        data: { type: :jat, id: 'OBJECT' },
        meta: { foo: :bar }
      )
    end
  end

  describe '#to_str' do
    it 'returns json string' do
      jat.type :jat
      jat.id key: :itself

      result = jat.new.to_str('OBJECT', meta: { foo: :bar })
      expect(result).to eq JSON.dump(
        data: { type: :jat, id: 'OBJECT' },
        meta: { foo: :bar }
      )
    end
  end

  describe 'caching' do
    let(:opts) { { cache: hash_cache } }
    let(:hash_storage) { {} }
    let(:hash_cache) do
      hash_storage
      lambda do |object, params, format, &block|
        key = [object, :fields, *params[:fields].to_a.flatten, format].join('.').freeze
        hash_storage[key] ||= block.()
      end
    end
    let(:serializer) { jat.new(fields: { jat: 'number' }) }

    before do
      jat.type :jat
      jat.id key: :itself
      jat.attribute(:number) { |obj| obj[-1] }
    end

    it 'caches #to_h' do
      allow(Jat::Response).to receive(:new).twice.and_call_original

      result1 = serializer.to_h('OBJECT_1', opts) # this should construct response
      result2 = serializer.to_h('OBJECT_1', opts) # this should be taken from cache
      result3 = serializer.to_h('OBJECT_2', opts) # this should construct response

      expect(result1).to eq(data: { type: :jat, id: 'OBJECT_1', attributes: { number: '1' } })
      expect(result2).to eq(data: { type: :jat, id: 'OBJECT_1', attributes: { number: '1' } })
      expect(result3).to eq(data: { type: :jat, id: 'OBJECT_2', attributes: { number: '2' } })

      # Tests that we can use object, params and current format (hash) as cache key
      expect(hash_storage).to eq(
        'OBJECT_1.fields.jat.number.hash' => { data: { type: :jat, id: 'OBJECT_1', attributes: { number: '1' } } },
        'OBJECT_2.fields.jat.number.hash' => { data: { type: :jat, id: 'OBJECT_2', attributes: { number: '2' } } }
      )

      expect(Jat::Response).to have_received(:new).twice
    end

    it 'caches #to_str' do
      allow(Jat::Response).to receive(:new).twice.and_call_original

      result1 = serializer.to_str('OBJECT_1', opts) # this should construct response
      result2 = serializer.to_str('OBJECT_1', opts) # this should be taken from cache
      result3 = serializer.to_str('OBJECT_2', opts) # this should construct response

      expect(result1).to eq JSON.dump(data: { type: :jat, id: 'OBJECT_1', attributes: { number: '1' } })
      expect(result2).to eq JSON.dump(data: { type: :jat, id: 'OBJECT_1', attributes: { number: '1' } })
      expect(result3).to eq JSON.dump(data: { type: :jat, id: 'OBJECT_2', attributes: { number: '2' } })

      # Tests that we can use object, params and current format (string) as cache key
      expect(hash_storage).to eq(
        'OBJECT_1.fields.jat.number.string' =>
          JSON.dump(data: { type: :jat, id: 'OBJECT_1', attributes: { number: '1' } }),

        'OBJECT_2.fields.jat.number.string' =>
          JSON.dump(data: { type: :jat, id: 'OBJECT_2', attributes: { number: '2' } })
      )

      expect(Jat::Response).to have_received(:new).twice
    end
  end

  describe 'redefining params' do
    let(:serializer) { jat.new(params) }

    before do
      children_serializer = Class.new(described_class)
      children_serializer.type(:jat2)
      children_serializer.id key: :itself

      jat.type :jat
      jat.id key: :itself
      jat.attribute(:size, exposed: false)
      jat.relationship(:children, serializer: children_serializer) { 'jat2' }
    end

    it 'redefines params with #to_h' do
      ser = jat.new(fields: { jat: 'size' }) # response should not include `size` field defined here
      resp = ser.to_h('OBJECT', params: { include: 'children' }) # response should include `children` relation

      data = resp[:data]
      expect(data).to include(:relationships)
      expect(data).not_to include(:attributes)
    end

    it 'redefines params with #to_str' do
      ser = jat.new(fields: { jat: 'size' }) # response should not include `size` field defined here
      data = ser.to_str('OBJECT', params: { include: 'children' }) # response should include `children` relation

      expect(data).to include('relationships')
      expect(data).not_to include('attributes')
    end
  end

  describe '#_includes' do
    it 'delegates to Jat::Include with correct params' do
      jat.type :jat
      serializer = jat.new

      includes = instance_double(Jat::Includes)
      allow(Jat::Includes).to receive(:new).with(serializer.send(:_full_map)).and_return(includes)
      allow(includes).to receive(:for).with(serializer.class).and_return('RES')

      expect(serializer._includes).to eq 'RES'
    end
  end

  describe 'inheritance' do
    it 'inherits config' do
      parent = jat
      parent.config.exposed = :none

      child = Class.new(parent)
      expect(child.config.exposed).to eq :none
    end

    it 'does not overwrites parent config' do
      parent = jat
      parent.config.exposed = :all

      child = Class.new(parent)
      child.config.exposed = :none

      expect(parent.config.exposed).to eq :all
    end

    it 'inherits type and attributes' do
      parent = jat
      parent.type :parent
      parent.attribute :foo, exposed: true
      parent.relationship :bar, serializer: -> { parent }, exposed: false

      child = Class.new(parent)
      expect(child.type).to eq :parent
      expect(child.attributes[:foo].exposed).to eq true
      expect(child.attributes[:bar].exposed).to eq false
    end

    it 'does not overwrites parent attributes' do
      parent = jat
      child = Class.new(parent)
      child.attribute :foo

      expect(parent.attributes[:foo]).to eq nil
    end
  end

  it 'refreshes attributes when config updated' do
    attribute = jat.attribute :foo
    expect(attribute).to be_exposed # before

    jat.config.exposed = :none
    expect(attribute).not_to be_exposed # after
  end

  it 'nullifies @full_map and @exposed_map when settings changed' do
    jat.type(:jat)
    jat.attribute :foo
    jat.full_map
    jat.exposed_map

    # Before
    expect(jat.instance_variable_get(:@full_map)).to be_any
    expect(jat.instance_variable_get(:@exposed_map)).to be_any

    jat.config.delegate = false

    # After
    expect(jat.instance_variable_get(:@full_map)).to eq nil
    expect(jat.instance_variable_get(:@exposed_map)).to eq nil
  end
end
