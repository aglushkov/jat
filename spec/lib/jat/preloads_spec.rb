# frozen_string_literal: true

RSpec.describe Jat::Preloads do
  let(:user_serializer) do
    ser = Class.new(Jat)
    ser.type :user
    ser
  end

  let(:profile_serializer) do
    ser = Class.new(Jat)
    ser.type :profile
    ser
  end

  let(:email_serializer) do
    ser = Class.new(Jat)
    ser.type :email
    ser
  end

  before { Jat.config.auto_preload = true }

  it 'returns empty hash when no attributes requested' do
    types_keys = { user: { attributes: [], relationships: [] } }

    result = described_class.new(types_keys).for(user_serializer)
    expect(result).to eq({})
  end

  it 'returns empty hash when no attributes with preloads requested' do
    user_serializer.attribute :name
    types_keys = { user: { attributes: [:name], relationships: [] } }

    result = described_class.new(types_keys).for(user_serializer)
    expect(result).to eq({})
  end

  it 'returns preloads for requested attributes' do
    user_serializer.attribute :name, preload: :profile
    types_keys = { user: { attributes: [:name], relationships: [] } }

    result = described_class.new(types_keys).for(user_serializer)
    expect(result).to eq(profile: {})
  end

  it 'returns merged preloads for requested attributes' do
    user_serializer.attribute :first_name, preload: :profile
    user_serializer.attribute :phone, preload: { profile: :phones }
    user_serializer.attribute :email, preload: { profile: :emails }

    types_keys = { user: { attributes: %i[first_name phone email], relationships: [] } }

    result = described_class.new(types_keys).for(user_serializer)
    expect(result).to eq(profile: { phones: {}, emails: {} })
  end

  it 'returns no preloads and no nested preloads for relationships when specified preloads is nil' do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: nil
    profile_serializer.attribute :email, preload: :email # should not be preloaded
    types_keys = {
      user: { attributes: [], relationships: %i[profile] },
      profile: { attributes: %i[email], relationships: [] }
    }

    result = described_class.new(types_keys).for(user_serializer)
    expect(result).to eq({})
  end

  it 'returns preloads for nested relationships joined to root when specified preloads is {} or []' do
    [{}, []].each do |preloads|
      user_serializer.relationship :profile, serializer: profile_serializer, preload: preloads
      profile_serializer.attribute :email, preload: :email # should be preloaded to root
      types_keys = {
        user: { attributes: [], relationships: %i[profile] },
        profile: { attributes: %i[email], relationships: [] }
      }

      result = described_class.new(types_keys).for(user_serializer)
      expect(result).to eq(email: {})
    end
  end

  it 'returns preloads for relationships' do
    user_serializer.relationship :profile, serializer: profile_serializer
    types_keys = {
      user: { attributes: [], relationships: %i[profile] },
      profile: { attributes: [], relationships: [] }
    }

    result = described_class.new(types_keys).for(user_serializer)
    expect(result).to eq(profile: {})
  end

  it 'returns nested preloads for relationships' do
    user_serializer.relationship :profile, serializer: profile_serializer
    profile_serializer.attribute :email, preload: %i[confirmed_email unconfirmed_email]

    types_keys = {
      user: { attributes: [], relationships: %i[profile] },
      profile: { attributes: %i[email], relationships: [] }
    }

    result = described_class.new(types_keys).for(user_serializer)
    expect(result).to eq(profile: { confirmed_email: {}, unconfirmed_email: {} })
  end

  it 'preloads nested relationships for nested relationship' do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: { company: :profile }
    profile_serializer.attribute :email, preload: %i[confirmed_email unconfirmed_email]

    types_keys = {
      user: { attributes: [], relationships: %i[profile] },
      profile: { attributes: %i[email], relationships: [] }
    }

    result = described_class.new(types_keys).for(user_serializer)
    expect(result).to eq(company: { profile: { confirmed_email: {}, unconfirmed_email: {} } })
  end

  it 'preloads nested relationships to main (!) resource' do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: { company!: :profile }
    profile_serializer.attribute :email, preload: %i[confirmed_email unconfirmed_email]

    types_keys = {
      user: { attributes: [], relationships: %i[profile] },
      profile: { attributes: %i[email], relationships: [] }
    }

    result = described_class.new(types_keys).for(user_serializer)
    expect(result).to eq(company: { profile: {}, confirmed_email: {}, unconfirmed_email: {} })
  end

  it 'raises error if with 2 serializers have recursive preloads' do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: :profile
    profile_serializer.relationship :user, serializer: user_serializer, preload: :user

    types_keys = {
      user: { attributes: [], relationships: %i[profile] },
      profile: { attributes: [], relationships: %i[user] }
    }

    expect { described_class.new(types_keys).for(user_serializer) }
      .to raise_error Jat::Error, /recursive preloads/
  end

  it 'raises error if 3 serializers recursive preloads' do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: :profile
    profile_serializer.relationship :email, serializer: email_serializer, preload: :email
    email_serializer.relationship :user, serializer: user_serializer, preload: :user

    types_keys = {
      user: { attributes: [], relationships: %i[profile] },
      profile: { attributes: [], relationships: %i[email] },
      email: { attributes: [], relationships: %i[user] }
    }

    expect { described_class.new(types_keys).for(user_serializer) }
      .to raise_error Jat::Error, /recursive preloads/
  end

  it 'does not raises error if 2 serializers preloads same preloads' do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: :profile
    user_serializer.relationship :email, serializer: email_serializer, preload: :email
    profile_serializer.relationship :email, serializer: email_serializer, preload: :email

    types_keys = {
      user: { attributes: [], relationships: %i[profile email] },
      profile: { attributes: [], relationships: %i[email] },
      email: { attributes: [], relationships: %i[] }
    }

    expect { described_class.new(types_keys).for(user_serializer) }.not_to raise_error
  end

  it 'merges preloads the same way regardless of order of preloads' do
    a = Class.new(Jat) { type(:a) }
    a.attribute :a1, preload: { foo: { bar: { bazz1: {}, bazz: {} } } }
    a.attribute :a2, preload: { foo: { bar: { bazz2: {}, bazz: { last: {} } } } }

    types_keys1 = { a: { attributes: %i[a1 a2], relationships: %i[] } }
    types_keys2 = { a: { attributes: %i[a2 a1], relationships: %i[] } }

    result1 = described_class.new(types_keys1).for(a)
    result2 = described_class.new(types_keys2).for(a)

    expect(result1).to eq(result2)
    expect(result1).to eq(foo: { bar: { bazz: { last: {} }, bazz1: {}, bazz2: {} } })
  end
end
