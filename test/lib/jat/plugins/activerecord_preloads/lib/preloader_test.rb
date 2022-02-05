# frozen_string_literal: true

require "test_helper"
require "support/activerecord"

describe "Jat::Plugins::ActiverecordPreloads" do
  before { serializer_class }

  # Plugin can be used only together with :simple_api or :json_api
  let(:serializer_class) do
    Class.new(Jat) do
      plugin :simple_api
      plugin :activerecord_preloads
    end
  end

  describe "Preloader" do
    let(:described_class) { plugin::Preloader }
    let(:plugin) { Jat::Plugins::ActiverecordPreloads }

    describe ".handlers" do
      it "returns memorized array of handlers" do
        assert_equal [
          plugin::ActiverecordRelation,
          plugin::ActiverecordObject,
          plugin::ActiverecordArray
        ], described_class.handlers

        assert_same described_class.handlers, described_class.handlers
      end
    end

    describe ".preload" do
      it "raises error when can't find appropriate handler" do
        preloads = {}

        object = nil
        err = assert_raises(Jat::Error) { described_class.preload(object, {}) }
        assert_equal "Can't preload #{preloads.inspect} to #{object.inspect}", err.message

        object = []
        err = assert_raises(Jat::Error) { described_class.preload(object, {}) }
        assert_equal "Can't preload #{preloads.inspect} to #{object.inspect}", err.message

        object = 123
        err = assert_raises(Jat::Error) { described_class.preload(object, {}) }
        assert_equal "Can't preload #{preloads.inspect} to #{object.inspect}", err.message

        object = [AR::User.create!, AR::Comment.create!]
        err = assert_raises(Jat::Error) { described_class.preload(object, {}) }
        assert_equal "Can't preload #{preloads.inspect} to #{object.inspect}", err.message
      end

      it "preloads data to activerecord object" do
        user = AR::User.create!

        result = described_class.preload(user, {comments: {}})

        assert_same result, user
        assert_equal true, user.association(:comments).loaded?
      end

      it "preloads data to activerecord array" do
        user = AR::User.create!

        users = [user]
        result = described_class.preload(users, {comments: {}})

        assert_same result, users
        assert_equal true, result[0].association(:comments).loaded?
      end

      it "preloads data to activerecord relation" do
        user = AR::User.create!

        result = described_class.preload(AR::User.where(id: user.id), {comments: {}})

        assert_equal result, [user]
        assert_equal true, result[0].association(:comments).loaded?
      end

      it "preloads data to loaded activerecord relation" do
        user = AR::User.create!

        result = described_class.preload(AR::User.where(id: user.id).load, {comments: {}})

        assert_equal result, [user]
        assert_equal true, result[0].association(:comments).loaded?
      end
    end
  end
end
