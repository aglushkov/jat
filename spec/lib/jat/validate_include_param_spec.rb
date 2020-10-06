# frozen_string_literal: true

RSpec.describe Jat::ValidateIncludeParam do
  let(:a_serializer) { Class.new(Jat) }
  let(:b_serializer) { Class.new(Jat) }

  before do
    ser = a_serializer
    ser.type :a
    ser.attribute :a1
    ser.relationship :a2, serializer: b_serializer
    ser.relationship :a3, serializer: b_serializer

    ser = b_serializer
    ser.type :b
    ser.attribute :b1
    ser.relationship :b2, serializer: a_serializer
  end

  it 'does not raises error when all include are valid' do
    include_param = { a2: { b2: { a2: { b2: { a2: {} } } } }, a3: { b2: { a2: { b2: { a2: {} } } } } }
    expect { described_class.(a_serializer, include_param) }.not_to raise_error
  end

  it 'raises error when some key is invalid' do
    expect { described_class.(a_serializer, foo: {}) }
      .to raise_error Jat::InvalidIncludeParam, "#{a_serializer} has no `foo` relationship"
  end

  it 'raises error when some children key is invalid' do
    expect { described_class.(a_serializer, a2: { foo: {} }) }
      .to raise_error Jat::InvalidIncludeParam, "#{b_serializer} has no `foo` relationship"
  end

  it 'raises error when trying to include attribute, not relationship' do
    expect { described_class.(a_serializer, a1: {}) }
      .to raise_error Jat::InvalidIncludeParam, "#{a_serializer} has no `a1` relationship"
  end

  it 'raises error when trying to include attribute to children' do
    expect { described_class.(a_serializer, a2: { b1: {} }) }
      .to raise_error Jat::InvalidIncludeParam, "#{b_serializer} has no `b1` relationship"
  end
end
