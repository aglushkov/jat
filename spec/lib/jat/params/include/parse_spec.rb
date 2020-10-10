# frozen_string_literal: true

RSpec.describe Jat::Params::Include::Parse do
  it 'returns empty hash when param not provided' do
    result = described_class.(nil)

    expect(result).to eq({})
  end

  it 'returns hash when single element' do
    result = described_class.('foo')

    expect(result).to eq(foo: {})
  end

  it 'returns hash when multiple elements' do
    result = described_class.('foo,bar,bazz')

    expect(result).to eq(foo: {}, bar: {}, bazz: {})
  end

  it 'returns hash when nested elements' do
    result = described_class.('foo.bar.bazz')

    expect(result).to eq(foo: { bar: { bazz: {} } })
  end

  it 'returns hash when multiple nested elements' do
    result = described_class.('foo,bar.bazz,bar.bazzz,test.test1.test2,test.test1.test3')

    expect(result).to eq(
      foo: {},
      bar: { bazz: {}, bazzz: {} },
      test: { test1: { test2: {}, test3: {} } }
    )
  end
end
