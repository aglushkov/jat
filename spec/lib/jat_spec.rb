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
      expect(jat.keys[:foo].relation?).to eq false
    end

    it 'allows to redefine attribute' do
      jat.attribute(:foo, delegate: true)
      expect(jat.keys[:foo].delegate?).to eq true

      jat.attribute(:foo, delegate: false)
      expect(jat.keys[:foo].delegate?).to eq false
    end
  end

  describe '.relationship' do
    it 'adds relationship' do
      jat.attribute :foo, serializer: jat
      expect(jat.keys[:foo].serializer).to eq jat
    end

    it 'allows to redefine relationship' do
      jat.attribute(:foo, exposed: true, serializer: jat)
      expect(jat.keys[:foo].exposed?).to eq true

      jat.attribute(:foo, exposed: false, serializer: jat)
      expect(jat.keys[:foo].exposed?).to eq false
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
