# frozen_string_literal: true

require "test_helper"

describe "Jat::Plugins::SimpleApi::FieldsParamParser" do
  before do
    Jat::Plugins.find_plugin :simple_api
  end

  let(:serializer_class) do
    ser = Class.new(Jat)
    ser.plugin :simple_api
    ser
  end

  let(:described_class) { serializer_class::FieldsParamParser }

  def parse(str)
    serializer_class::FieldsParamParser.parse(str)
  end

  describe ".parse" do
    it "returns empty hash when nil provided" do
      assert_equal({}, parse(nil))
    end

    it "returns empty hash when empty string provided" do
      assert_equal({}, parse(""))
    end

    it "parses single field" do
      assert_equal({id: {}}, parse("id"))
    end

    it "parses multiple fields" do
      assert_equal({id: {}, name: {}}, parse("id, name"))
    end

    it "parses single resource with single field" do
      assert_equal({users: {id: {}}}, parse("users(id)"))
    end

    it "parses fields started with open PAREN" do
      assert_equal({users: {id: {}}}, parse("(users(id))"))
    end

    it "parses fields started with extra close PAREN" do
      assert_equal({users: {}}, parse(")users)"))
    end

    it "parses single resource with multiple fields" do
      assert_equal({users: {id: {}, name: {}}}, parse("users(id,name)"))
    end

    it "parses multiple resources with fields" do
      fields = "id,posts(title,text),news(title,text)"
      resp = {
        id: {},
        posts: {title: {}, text: {}},
        news: {title: {}, text: {}}
      }

      assert_equal(resp, parse(fields))
    end

    it "parses included resources" do
      fields = "id,posts(title,text,comments(author(name),comment))"
      resp = {
        id: {},
        posts: {
          title: {},
          text: {},
          comments: {
            author: {
              name: {}
            },
            comment: {}
          }
        }
      }

      assert_equal(resp, parse(fields))
    end
  end
end
