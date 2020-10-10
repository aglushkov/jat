# frozen_string_literal: true

RSpec.describe Jat::Params::Fields do
  let(:serializer) { Class.new(Jat) }

  before do
    serializer.type :a

    serializer.attribute :a1
    serializer.attribute :a2
    serializer.attribute :a3
  end

  it 'returns empty hash when param not provided' do
    result = described_class.(serializer, nil)

    expect(result).to eq({})
  end

  it 'returns typed keys' do
    result = described_class.(serializer, a: 'a1,a2')

    expect(result).to eq(a: %i[a1 a2])
  end

  it 'validates provided keys' do
    expect { described_class.(serializer, a: 'a1,a2,a3,a4') }
      .to raise_error Jat::Params::Fields::Invalid, /a4/
  end
end
