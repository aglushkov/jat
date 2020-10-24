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

  describe '#_includes' do
    it 'delegates to Jat::Include with correct params' do
      jat.type :jat
      serializer = jat.new

      includes = instance_double(Jat::Includes)
      allow(Jat::Includes).to receive(:new).with(serializer._full_map).and_return(includes)
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
