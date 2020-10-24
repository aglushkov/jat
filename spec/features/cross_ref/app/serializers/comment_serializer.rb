# frozen_string_literal: true

require_relative './user_serializer'

module CrossRef
  class CommentSerializer < Jat
    type :comment

    relationship :user,
                 exposed: true,
                 serializer: -> { CrossRef::UserSerializer }
  end
end
