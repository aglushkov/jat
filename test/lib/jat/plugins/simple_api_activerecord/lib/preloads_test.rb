# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApiActiverecord::Preloads" do
  let(:base) { Class.new(Jat) { plugin :simple_api, activerecord: true } }

  let(:user_serializer) { Class.new(base) }
  let(:profile_serializer) { Class.new(base) }
  let(:email_serializer) { Class.new(base) }

  let(:jat_user) { user_serializer.new }
  let(:jat_profile) { profile_serializer.new }
  let(:jat_email) { email_serializer.new }

  let(:described_class) { Jat::Plugins::SimpleApiActiverecord::Preloads }

  def define_map(map)
    user_serializer::Map.expects(:call).returns(map)
  end

  it "returns empty hash when no attributes requested" do
    define_map({})

    result = described_class.call(jat_user)
    assert_equal({}, result)
  end

  it "returns empty hash when no attributes with preloads requested" do
    user_serializer.attribute :name
    define_map({name: {}})

    result = described_class.call(jat_user)
    assert_equal({}, result)
  end

  it "returns preloads for requested attributes" do
    user_serializer.attribute :name, preload: :profile
    define_map({name: {}})

    result = described_class.call(jat_user)
    assert_equal({profile: {}}, result)
  end

  it "returns merged preloads for requested attributes" do
    user_serializer.attribute :first_name, preload: :profile
    user_serializer.attribute :phone, preload: {profile: :phones}
    user_serializer.attribute :email, preload: {profile: :emails}

    define_map({first_name: {}, phone: {}, email: {}})

    result = described_class.call(jat_user)
    assert_equal({profile: {phones: {}, emails: {}}}, result)
  end

  it "returns no preloads and no nested preloads for relationships when specified preloads is nil" do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: nil
    profile_serializer.attribute :email, preload: :email # should not be preloaded
    define_map(profile: {email: {}})

    result = described_class.call(jat_user)
    assert_equal({}, result)
  end

  it "returns preloads for nested relationships joined to root when specified preloads is {}" do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: {}
    profile_serializer.attribute :email, preload: :email # should be preloaded to root
    define_map({profile: {email: {}}})

    result = described_class.call(jat_user)
    assert_equal({email: {}}, result)
  end

  it "returns preloads for nested relationships joined to root when specified preloads is []" do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: []
    profile_serializer.attribute :email, preload: :email # should be preloaded to root
    define_map({profile: {email: {}}})

    result = described_class.call(jat_user)
    assert_equal({email: {}}, result)
  end

  it "returns preloads for relationships" do
    user_serializer.relationship :profile, serializer: profile_serializer
    define_map(profile: {})

    result = described_class.call(jat_user)
    assert_equal({profile: {}}, result)
  end

  it "returns nested preloads for relationships" do
    user_serializer.relationship :profile, serializer: profile_serializer
    profile_serializer.attribute :email, preload: %i[confirmed_email unconfirmed_email]
    define_map(profile: {email: {}})

    result = described_class.call(jat_user)
    assert_equal({profile: {confirmed_email: {}, unconfirmed_email: {}}}, result)
  end

  it "preloads nested relationships for nested relationship" do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: {company: :profile}
    profile_serializer.attribute :email, preload: %i[confirmed_email unconfirmed_email]
    define_map(profile: {email: {}})

    result = described_class.call(jat_user)
    assert_equal({company: {profile: {confirmed_email: {}, unconfirmed_email: {}}}}, result)
  end

  it "preloads nested relationships to main (!) resource" do
    user_serializer.relationship :profile, serializer: profile_serializer, preload: {company!: :profile}
    profile_serializer.attribute :email, preload: %i[confirmed_email unconfirmed_email]
    define_map(profile: {email: {}})

    result = described_class.call(jat_user)
    assert_equal({company: {profile: {}, confirmed_email: {}, unconfirmed_email: {}}}, result)
  end

  it "merges preloads the same way regardless of order of preloads" do
    a = Class.new(base)
    a.attribute :a1, preload: {foo: {bar: {bazz1: {}, bazz: {}}}}
    a.attribute :a2, preload: {foo: {bar: {bazz2: {}, bazz: {last: {}}}}}

    jat_a1 = a.allocate
    jat_a2 = a.allocate

    jat_a1.expects(:map).returns({a1: {}, a2: {}})
    jat_a2.expects(:map).returns({a2: {}, a1: {}})

    result1 = described_class.call(jat_a1)
    result2 = described_class.call(jat_a2)

    assert_equal(result2, result1)
    assert_equal({foo: {bar: {bazz: {last: {}}, bazz1: {}, bazz2: {}}}}, result1)
  end
end
