# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::JsonApiActiverecord::Preloads" do
  let(:base) { Class.new(Jat) { plugin :json_api, activerecord: true } }

  let(:user_serializer) { Class.new(base) { type(:user) } }
  let(:profile_serializer) { Class.new(base) { type(:profile) } }
  let(:email_serializer) { Class.new(base) { type(:email) } }

  let(:jat_user) { user_serializer.allocate }
  let(:jat_profile) { profile_serializer.allocate }
  let(:jat_email) { email_serializer.allocate }

  let(:described_class) { Jat::Plugins::JsonApiActiverecord::Preloads }

  def define_map(map)
    jat_user.traversal_map.expects(:current).returns(map)
  end

  it "returns empty hash when no attributes requested" do
    define_map(user: {attributes: [], relationships: []})

    result = described_class.call(jat_user)
    assert_equal({}, result)
  end

  it "returns empty hash when no attributes with preloads requested" do
    user_serializer.attribute :name
    define_map(user: {attributes: [:name], relationships: []})

    result = described_class.call(jat_user)
    assert_equal({}, result)
  end

  it "returns preloads for requested attributes" do
    user_serializer.attribute :name, preload: :profile
    define_map(user: {attributes: [:name], relationships: []})

    result = described_class.call(jat_user)
    assert_equal({profile: {}}, result)
  end

  it "returns merged preloads for requested attributes" do
    user_serializer.attribute :first_name, preload: :profile
    user_serializer.attribute :phone, preload: {profile: :phones}
    user_serializer.attribute :email, preload: {profile: :emails}

    define_map(user: {attributes: %i[first_name phone email], relationships: []})

    result = described_class.call(jat_user)
    assert_equal({profile: {phones: {}, emails: {}}}, result)
  end

  it "returns no preloads and no nested preloads for relationships when specified preloads is nil" do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: nil
    profile_serializer.attribute :email, preload: :email # should not be preloaded
    define_map(
      user: {attributes: [], relationships: %i[profile]},
      profile: {attributes: %i[email], relationships: []}
    )

    result = described_class.call(jat_user)
    assert_equal({}, result)
  end

  it "returns preloads for nested relationships joined to root when specified preloads is {} or []" do
    [{}, []].each do |preloads|
      user_serializer.relationship :profile, serializer: profile_serializer, preload: preloads
      profile_serializer.attribute :email, preload: :email # should be preloaded to root
      define_map(
        user: {attributes: [], relationships: %i[profile]},
        profile: {attributes: %i[email], relationships: []}
      )

      result = described_class.call(jat_user)
      assert_equal({email: {}}, result)
    end
  end

  it "returns preloads for relationships" do
    user_serializer.relationship :profile, serializer: profile_serializer
    define_map(
      user: {attributes: [], relationships: %i[profile]},
      profile: {attributes: [], relationships: []}
    )

    result = described_class.call(jat_user)
    assert_equal({profile: {}}, result)
  end

  it "returns nested preloads for relationships" do
    user_serializer.relationship :profile, serializer: profile_serializer
    profile_serializer.attribute :email, preload: %i[confirmed_email unconfirmed_email]

    define_map(
      user: {attributes: [], relationships: %i[profile]},
      profile: {attributes: %i[email], relationships: []}
    )

    result = described_class.call(jat_user)
    assert_equal({profile: {confirmed_email: {}, unconfirmed_email: {}}}, result)
  end

  it "preloads nested relationships for nested relationship" do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: {company: :profile}
    profile_serializer.attribute :email, preload: %i[confirmed_email unconfirmed_email]

    define_map(
      user: {attributes: [], relationships: %i[profile]},
      profile: {attributes: %i[email], relationships: []}
    )

    result = described_class.call(jat_user)
    assert_equal({company: {profile: {confirmed_email: {}, unconfirmed_email: {}}}}, result)
  end

  it "preloads nested relationships to main (!) resource" do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: {company!: :profile}
    profile_serializer.attribute :email, preload: %i[confirmed_email unconfirmed_email]

    define_map(
      user: {attributes: [], relationships: %i[profile]},
      profile: {attributes: %i[email], relationships: []}
    )

    result = described_class.call(jat_user)
    assert_equal({company: {profile: {}, confirmed_email: {}, unconfirmed_email: {}}}, result)
  end

  it "raises error if with 2 serializers have recursive preloads" do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: :profile
    profile_serializer.relationship :user, serializer: user_serializer, preload: :user

    define_map(
      user: {attributes: [], relationships: %i[profile]},
      profile: {attributes: [], relationships: %i[user]}
    )

    error = assert_raises(Jat::Error) { described_class.call(jat_user) }
    assert_match(/recursive preloads/, error.message)
  end

  it "raises error if 3 serializers recursive preloads" do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: :profile
    profile_serializer.relationship :email, serializer: email_serializer, preload: :email
    email_serializer.relationship :user, serializer: user_serializer, preload: :user

    define_map(
      user: {attributes: [], relationships: %i[profile]},
      profile: {attributes: [], relationships: %i[email]},
      email: {attributes: [], relationships: %i[user]}
    )

    error = assert_raises(Jat::Error) { described_class.call(jat_user) }
    assert_match(/recursive preloads/, error.message)
  end

  it "does not raises error if 2 serializers preloads same preloads" do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: :profile
    user_serializer.relationship :email, serializer: email_serializer, preload: :email
    profile_serializer.relationship :email, serializer: email_serializer, preload: :email

    define_map(
      user: {attributes: [], relationships: %i[profile email]},
      profile: {attributes: [], relationships: %i[email]},
      email: {attributes: [], relationships: %i[]}
    )

    described_class.call(jat_user) # should not raise
  end

  it "merges preloads the same way regardless of order of preloads" do
    a = Class.new(base) { type(:a) }
    a.attribute :a1, preload: {foo: {bar: {bazz1: {}, bazz: {}}}}
    a.attribute :a2, preload: {foo: {bar: {bazz2: {}, bazz: {last: {}}}}}

    jat_a1 = a.allocate
    jat_a2 = a.allocate

    jat_a1.traversal_map.expects(:current).returns(a: {attributes: %i[a1 a2], relationships: %i[]})
    jat_a2.traversal_map.expects(:current).returns(a: {attributes: %i[a2 a1], relationships: %i[]})

    result1 = described_class.call(jat_a1)
    result2 = described_class.call(jat_a2)

    assert_equal(result2, result1)
    assert_equal({foo: {bar: {bazz: {last: {}}, bazz1: {}, bazz2: {}}}}, result1)
  end
end
