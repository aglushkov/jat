# frozen_string_literal: true

RSpec.describe Jat::Plugins::JSON_API::RequestedIncludeParam do
  let(:a_serializer) { Class.new(Jat) }
  let(:b_serializer) { Class.new(Jat) }

  before do
    ser = a_serializer
    ser.type :a
    ser.attribute :a1
    ser.relationship :a2, serializer: b_serializer
    ser.relationship :a3, serializer: b_serializer
    ser.relationship :a4, serializer: b_serializer
    ser.relationship :a5, serializer: b_serializer

    ser = b_serializer
    ser.type :b
    ser.attribute :b1
    ser.relationship :b2, serializer: a_serializer
    ser.relationship :b3, serializer: a_serializer
    ser.relationship :b4, serializer: a_serializer
  end

  it 'returns empty hash when param not provided' do
    result = described_class.(a_serializer, nil)

    expect(result).to eq({})
  end

  it 'returns typed keys' do
    result = described_class.(a_serializer, 'a2.b2,a2.b3,a3.b2.a2,a4')

    expect(result).to eq(
      a: %i[a2 a3 a4],
      b: %i[b2 b3]
    )
  end

  it 'works with polymorphic associations' do
    main_ser = Class.new(Jat)
    main_ser.type :main

    a_serializer.relationship :common1, serializer: a_serializer
    a_serializer.relationship :common2, serializer: a_serializer
    b_serializer.relationship :common1, serializer: b_serializer
    b_serializer.relationship :common2, serializer: b_serializer

    main_ser.relationship :polym, serializer: [a_serializer, b_serializer]
    include_param = 'polym.common1,polym.common2'

    result = described_class.(main_ser, include_param)

    expect(result).to eq(
      main: %i[polym],
      a: %i[common1 common2],
      b: %i[common1 common2]
    )
  end
end
