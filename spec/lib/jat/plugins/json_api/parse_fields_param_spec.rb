# frozen_string_literal: true

RSpec.describe Jat::Plugins::JSON_API::ParseFieldsParam do
  it 'returns empty hash when param not provided' do
    result = described_class.(nil)

    expect(result).to eq({})
  end

  it 'returns hash with parsed keys' do
    result = described_class.(type1: 'a1,a2', type2: 'b1')

    expect(result).to eq(type1: %i[a1 a2], type2: %i[b1])
  end
end
