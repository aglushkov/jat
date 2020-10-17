# frozen_string_literal: true

RSpec.describe Jat::Map::Construct do
  let(:a) do
    ser = Class.new(Jat)
    ser.type :a

    ser.attribute :a1
    ser.attribute :a2
    ser.attribute :a3, exposed: false

    ser.relationship :b, serializer: b
    ser.relationship :c, serializer: c
    ser.relationship :d, serializer: d, exposed: true
    ser
  end

  let(:b) do
    ser = Class.new(Jat)
    ser.type :b
    ser.attribute :b1
    ser.attribute :b2
    ser.attribute :b3, exposed: false
    ser
  end

  let(:c) do
    ser = Class.new(Jat)
    ser.type :c
    ser.attribute :c1
    ser.attribute :c2
    ser.attribute :c3, exposed: false
    ser
  end

  let(:d) do
    ser = Class.new(Jat)
    ser.type :d
    ser.attribute :d1
    ser.attribute :d2
    ser.attribute :d3, exposed: false
    ser
  end

  it 'returns all attributes' do
    result = described_class.new(a, :all).to_h

    expect(result).to eq(
      a: { serializer: a, attributes: %i[a1 a2 a3], relationships: %i[b c d] },
      b: { serializer: b, attributes: %i[b1 b2 b3], relationships: [] },
      c: { serializer: c, attributes: %i[c1 c2 c3], relationships: [] },
      d: { serializer: d, attributes: %i[d1 d2 d3], relationships: [] }
    )
  end

  it 'returns exposed attributes' do
    result = described_class.new(a, :exposed).to_h

    expect(result).to eq(
      a: { serializer: a, attributes: %i[a1 a2], relationships: %i[d] },
      d: { serializer: d, attributes: %i[d1 d2], relationships: [] }
    )
  end

  it 'returns only manually exposed per-type attributes' do
    exposed = {
      a: %i[a2 a3 c d],
      c: %i[c2 c3],
      d: %i[d2 d3]
    }
    result = described_class.new(a, :none, exposed_additionally: exposed).to_h

    expect(result).to eq(
      a: { serializer: a, attributes: %i[a2 a3], relationships: %i[c d] },
      c: { serializer: c, attributes: %i[c2 c3], relationships: [] },
      d: { serializer: d, attributes: %i[d2 d3], relationships: [] }
    )
  end

  it 'returns combined auto-exposed and manualy exposed attributes' do
    exposed = {
      a: %i[c],
      c: %i[c3]
    }
    result = described_class.new(a, :exposed, exposed_additionally: exposed).to_h

    expect(result).to eq(
      a: { serializer: a, attributes: %i[a1 a2], relationships: %i[c d] },
      c: { serializer: c, attributes: %i[c1 c2 c3], relationships: [] },
      d: { serializer: d, attributes: %i[d1 d2], relationships: [] }
    )
  end
end
