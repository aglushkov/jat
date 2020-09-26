# frozen_string_literal: true

RSpec.describe Jat::Plugins::JSON_API::ValidateFieldsParam do
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

  it 'does not raises when serializer includes requested keys' do
    expect { described_class.(a_serializer, a: %i[a1 a2], b: %i[b1 b2]) }
      .not_to raise_error
  end

  it 'raises error when some type can not be in response  ' do
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

  it 'does not raises when polymorphoc serializer includes requested keys' do
    pol_serializer = Class.new(Jat)
    pol_serializer.type(:pol)
    pol_serializer.relationship :rel, serializer: [a_serializer, b_serializer]

    expect { described_class.(pol_serializer, pol: %i[rel], a: %i[a1 a2], b: %i[b1 b2]) }
      .not_to raise_error
  end
end
