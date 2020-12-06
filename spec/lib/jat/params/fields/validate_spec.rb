# frozen_string_literal: true

RSpec.describe Jat::Params::Fields::Validate do
  let(:a_serializer) { Class.new(Jat) }
  let(:b_serializer) { Class.new(Jat) }

  before do
    ser = a_serializer
    ser.type :a
    ser.attribute :a1
    ser.relationship :a2, serializer: b_serializer

    ser = b_serializer
    ser.type :b
    ser.attribute :b1
    ser.relationship :b2, serializer: a_serializer
  end

  it 'does not raises when serializer has all requested keys' do
    expect { described_class.(a_serializer, a: %i[a1 a2], b: %i[b1 b2]) }
      .not_to raise_error
  end

  it 'does not raises when requested only fields for nested serializer' do
    expect { described_class.(a_serializer, b: %i[b1 b2]) }
      .not_to raise_error
  end

  it 'raises error when some type can not be in response' do
    expect { described_class.(a_serializer, a: %i[a1 a2], foo: %i[b1 b2]) }
      .to raise_error "#{a_serializer} and its children have no requested type `foo`"
  end

  it 'raises error when some key is not present in main serializer' do
    expect { described_class.(a_serializer, a: %i[b1]) }
      .to raise_error "#{a_serializer} has no requested attribute or relationship `b1`"
  end

  it 'raises error when some key is not present in nested serializer' do
    expect { described_class.(a_serializer, a: %i[a1], b: %i[a1]) }
      .to raise_error "#{b_serializer} has no requested attribute or relationship `a1`"
  end
end
