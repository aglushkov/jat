# frozen_string_literal: true

RSpec.describe Jat::Utils::IncludesToHash do
  let(:hash) { described_class }

  it 'transforms nil to empty hash' do
    includes = nil
    expect(hash.(includes)).to eq({})
  end

  it 'transforms Symbol' do
    includes = :foo
    expect(hash.(includes)).to eq(foo: {})
  end

  it 'transforms String' do
    includes = 'foo'
    expect(hash.(includes)).to eq(foo: {})
  end

  it 'transforms Hash' do
    includes = { foo: :bar }
    expect(hash.(includes)).to eq(foo: { bar: {} })
  end

  it 'transforms Array' do
    includes = %i[foo bar]
    expect(hash.(includes)).to eq(foo: {}, bar: {})
  end

  it 'transforms nested hashes and arrays' do
    includes = [:foo, { 'bar' => 'bazz' }, ['bazz']]
    expect(hash.(includes)).to eq(foo: {}, bar: { bazz: {} }, bazz: {})

    includes = { 'bar' => 'bazz', foo: [:bar, 'bazz'] }
    expect(hash.(includes)).to eq(bar: { bazz: {} }, foo: { bar: {}, bazz: {} })
  end
end
