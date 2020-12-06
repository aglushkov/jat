# frozen_string_literal: true

RSpec.describe Jat::Utils::PreloadsToHash do
  let(:hash) { described_class }

  it 'transforms nil to empty hash' do
    preloads = nil
    expect(hash.(preloads)).to eq({})
  end

  it 'transforms Symbol' do
    preloads = :foo
    expect(hash.(preloads)).to eq(foo: {})
  end

  it 'transforms String' do
    preloads = 'foo'
    expect(hash.(preloads)).to eq(foo: {})
  end

  it 'transforms Hash' do
    preloads = { foo: :bar }
    expect(hash.(preloads)).to eq(foo: { bar: {} })
  end

  it 'transforms Array' do
    preloads = %i[foo bar]
    expect(hash.(preloads)).to eq(foo: {}, bar: {})
  end

  it 'transforms nested hashes and arrays' do
    preloads = [:foo, { 'bar' => 'bazz' }, ['bazz']]
    expect(hash.(preloads)).to eq(foo: {}, bar: { bazz: {} }, bazz: {})

    preloads = { 'bar' => 'bazz', foo: [:bar, 'bazz'] }
    expect(hash.(preloads)).to eq(bar: { bazz: {} }, foo: { bar: {}, bazz: {} })
  end
end
