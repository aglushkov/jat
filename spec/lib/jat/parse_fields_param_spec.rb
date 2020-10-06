# frozen_string_literal: true

RSpec.describe Jat::ParseFieldsParam do
  it 'returns empty hash when param not provided' do
    result = described_class.(nil)

    expect(result).to eq({})
  end

  it 'returns hash with parsed keys' do
    result = described_class.(a: 'a1,a2', b: 'b1')

    expect(result).to eq(a: %i[a1 a2], b: %i[b1])
  end
end
