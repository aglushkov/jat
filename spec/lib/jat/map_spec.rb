# frozen_string_literal: true

RSpec.describe Jat::Map do
  subject(:map) { described_class.(serializer, fields, includes) }

  let(:serializer) { Class.new(Jat) }
  let(:fields) { nil }
  let(:includes) { nil }

  context 'when no params given' do
    before { allow(serializer).to receive(:exposed_map).and_return('EXPOSED_MAP') }

    it 'returns map of exposed by default fields' do
      expect(map).to eq 'EXPOSED_MAP'
    end
  end

  context 'when fields given' do
    let(:fields) { 'FIELDS' }

    it 'constructs map with only provided fields' do
      constructor = instance_double(Jat::Map::Construct)

      allow(Jat::Params::Fields)
        .to receive(:call)
        .with(serializer, 'FIELDS')
        .and_return('PARSED_FIELDS')

      allow(Jat::Map::Construct)
        .to receive(:new)
        .with(serializer, :none, exposed_additionally: 'PARSED_FIELDS')
        .and_return(constructor)

      allow(constructor)
        .to receive(:to_h)
        .and_return('FIELDS_MAP')

      expect(map).to eq 'FIELDS_MAP'
    end
  end

  context 'when includes given' do
    let(:includes) { 'INCLUDES' }

    it 'constructs map with default and included fields' do
      constructor = instance_double(Jat::Map::Construct)

      allow(Jat::Params::Include)
        .to receive(:call)
        .with(serializer, 'INCLUDES')
        .and_return('PARSED_INCLUDES')

      allow(Jat::Map::Construct)
        .to receive(:new)
        .with(serializer, :default, exposed_additionally: 'PARSED_INCLUDES')
        .and_return(constructor)

      allow(constructor)
        .to receive(:to_h)
        .and_return('INCLUDES_MAP')

      expect(map).to eq 'INCLUDES_MAP'
    end
  end

  context 'when fields and includes given' do
    let(:fields) { 'FIELDS' }
    let(:includes) { 'INCLUDES' }

    it 'constructs map with only provided fields (and does not use includes)' do
      constructor = instance_double(Jat::Map::Construct)

      allow(Jat::Params::Fields)
        .to receive(:call)
        .with(serializer, 'FIELDS')
        .and_return('PARSED_FIELDS')

      allow(Jat::Map::Construct)
        .to receive(:new)
        .with(serializer, :none, exposed_additionally: 'PARSED_FIELDS')
        .and_return(constructor)

      allow(constructor)
        .to receive(:to_h)
        .and_return('FIELDS_MAP')

      expect(map).to eq 'FIELDS_MAP'
    end
  end
end
