# frozen_string_literal: true

require "test_helper"
require "support/activerecord"

describe "Jat::Plugins::ActiverecordPreloads" do
  before { Jat::Plugins.find_plugin(:_activerecord_preloads) }

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

      it "resets activerecord object preloaded relations" do
        user = AR::User.create!
        comment = user.comments.create!
        user.comments.to_a && comment.delete # preload comments manually and delete comment

        described_class.preload(user, {comments: {}})

        assert_equal true, user.association(:comments).loaded?
        assert_equal [], user.comments
      end

      it "preloads data to activerecord relation object" do
        user = AR::User.create!

        result = described_class.preload(AR::User.where(id: user.id), {comments: {}})

        assert_equal result, [user]
        assert_equal true, result[0].association(:comments).loaded?
      end

      it "preloads data to activerecord array" do
        user = AR::User.create!

        users = [user]
        result = described_class.preload(users, {comments: {}})

        assert_same result, users
        assert_equal true, result[0].association(:comments).loaded?
      end

      it "resets activerecord array preloaded relations" do
        user = AR::User.create!
        comment = user.comments.create!
        user.comments.to_a && comment.delete # preload comments manually and delete comment

        users = [user]
        result = described_class.preload(users, {comments: {}})

        assert_equal true, result[0].association(:comments).loaded?
        assert_equal [], result[0].comments
      end
    end
  end
end
