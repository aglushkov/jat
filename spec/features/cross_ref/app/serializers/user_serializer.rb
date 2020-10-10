# frozen_string_literal: true

require_relative './comment_serializer'

module CrossRef
  class UserSerializer < Jat
    type :user

    relationship :comments,
                 exposed: true,
                 serializer: CrossRef::CommentSerializer,
                 many: true
  end
end
