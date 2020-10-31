# frozen_string_literal: true

RSpec.describe Jat::Map do
  subject(:map) { described_class.(serializer, fields, includes) }

  let(:serializer) { Class.new(Jat) }
  let(:default_map) { { a: :a1, b: :b1, c: :c1 } }
  let(:includes_map) { { b: :b2, c: :c2 } }
  let(:fields_map) { { c: :c3 } }
  let(:includes) { nil }
  let(:fields) { nil }

  before { allow(serializer).to receive(:exposed_map).and_return(default_map) }

  context 'when no params given' do
    it 'returns map of exposed by default fields' do
      expect(map).to eq(default_map)
    end
  end

  context 'when fields given' do
    let(:fields) { 'FIELDS' }

    it 'constructs map with default and provided fields' do
      constructor = instance_double(Jat::Map::Construct, to_h: fields_map)
      allow(Jat::Params::Fields).to receive(:call).with(serializer, 'FIELDS').and_return('PARSED_FIELDS')
      allow(Jat::Map::Construct).to receive(:new).with(serializer, :manual, manually_exposed: 'PARSED_FIELDS')
                                                 .and_return(constructor)

      expect(map).to eq(a: :a1, b: :b1, c: :c3)
    end
  end

  context 'when includes given' do
    let(:includes) { 'INCLUDES' }

    it 'constructs map with default and included fields' do
      constructor = instance_double(Jat::Map::Construct, to_h: includes_map)
      allow(Jat::Params::Include).to receive(:call).with(serializer, 'INCLUDES').and_return('PARSED_INCLUDES')
      allow(Jat::Map::Construct).to receive(:new).with(serializer, :exposed, manually_exposed: 'PARSED_INCLUDES')
                                                 .and_return(constructor)

      expect(map).to eq(a: :a1, b: :b2, c: :c2)
    end
  end

  context 'when fields and includes given' do
    let(:fields) { 'FIELDS' }
    let(:includes) { 'INCLUDES' }

    it 'constructs map with all: defaults, includes, fields' do
      constructor1 = instance_double(Jat::Map::Construct, to_h: includes_map)
      allow(Jat::Params::Include).to receive(:call).with(serializer, 'INCLUDES').and_return('PARSED_INCLUDES')
      allow(Jat::Map::Construct).to receive(:new).with(serializer, :exposed, manually_exposed: 'PARSED_INCLUDES')
                                                 .and_return(constructor1)

      constructor2 = instance_double(Jat::Map::Construct, to_h: fields_map)
      allow(Jat::Params::Fields).to receive(:call).with(serializer, 'FIELDS').and_return('PARSED_FIELDS')
      allow(Jat::Map::Construct).to receive(:new).with(serializer, :manual, manually_exposed: 'PARSED_FIELDS')
                                                 .and_return(constructor2)

      expect(map).to eq(a: :a1, b: :b2, c: :c3)
    end
  end
end
