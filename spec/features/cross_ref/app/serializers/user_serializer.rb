# frozen_string_literal: true

module CrossRef
  class UserSerializer < Jat
    type :user

    relationship :comments,
                 exposed: true,
                 serializer: -> { CrossRef::CommentSerializer },
                 many: true
  end
end
