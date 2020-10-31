# frozen_string_literal: true

module CrossRef
  class CommentSerializer < Jat
    type :comment

    relationship :user,
                 exposed: true,
                 serializer: -> { CrossRef::UserSerializer }
  end
end
