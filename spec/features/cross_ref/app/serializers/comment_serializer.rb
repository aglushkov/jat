# frozen_string_literal: true

require_relative './user_serializer'

module CrossRef
  class CommentSerializer < Jat
    type :comment

    relationship :user,
                 exposed: false,
                 serializer: -> { CrossRef::UserSerializer },
                 many: false
  end
end
