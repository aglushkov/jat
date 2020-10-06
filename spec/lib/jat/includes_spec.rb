# frozen_string_literal: true

RSpec.describe Jat::Includes do
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

  it 'returns empty hash when no attributes requested' do
    types_keys = { user: { attributes: [], relationships: [] } }

    result = described_class.(user_serializer, types_keys)
    expect(result).to eq({})
  end

  it 'returns empty hash when no attributes with includes requested' do
    user_serializer.attribute :name
    types_keys = { user: { attributes: [:name], relationships: [] } }

    result = described_class.(user_serializer, types_keys)
    expect(result).to eq({})
  end

  it 'returns includes for requested attributes' do
    user_serializer.attribute :name, includes: :profile
    types_keys = { user: { attributes: [:name], relationships: [] } }

    result = described_class.(user_serializer, types_keys)
    expect(result).to eq(profile: {})
  end

  it 'returns merged includes for requested attributes' do
    user_serializer.attribute :first_name, includes: :profile
    user_serializer.attribute :phone, includes: { profile: :phones }
    user_serializer.attribute :email, includes: { profile: :emails }

    types_keys = { user: { attributes: %i[first_name phone email], relationships: [] } }

    result = described_class.(user_serializer, types_keys)
    expect(result).to eq(profile: { phones: {}, emails: {} })
  end

  it 'returns no includes for relationships when specified empty includes' do
    user_serializer.relationship :profile1, serializer: profile_serializer, includes: nil
    user_serializer.relationship :profile2, serializer: profile_serializer, includes: {}
    user_serializer.relationship :profile3, serializer: profile_serializer, includes: []

    types_keys = {
      user: { attributes: [], relationships: %i[profile1 profile2 profile3] },
      profile: { attributes: [], relationships: [] }
    }

    result = described_class.(user_serializer, types_keys)
    expect(result).to eq({})
  end

  it 'returns includes for relationships' do
    user_serializer.relationship :profile, serializer: profile_serializer
    types_keys = {
      user: { attributes: [], relationships: %i[profile] },
      profile: { attributes: [], relationships: [] }
    }

    result = described_class.(user_serializer, types_keys)
    expect(result).to eq(profile: {})
  end

  it 'returns nested includes for relationships' do
    user_serializer.relationship :profile, serializer: profile_serializer
    profile_serializer.attribute :email, includes: %i[confirmed_email unconfirmed_email]

    types_keys = {
      user: { attributes: [], relationships: %i[profile] },
      profile: { attributes: %i[email], relationships: [] }
    }

    result = described_class.(user_serializer, types_keys)
    expect(result).to eq(profile: { confirmed_email: {}, unconfirmed_email: {} })
  end

  # it 'returns all exposed includes' do
  #   comment_serializer.relationship :user, many: false, serializer: user_serializer, includes: :user, exposed: false

  #   expect(user_serializer.new._includes).to eq(
  #     confirmed_email: {},
  #     unconfirmed_email: {},
  #     profile: {},
  #     comments: { hashtags: {} }
  #   )
  # end
end
