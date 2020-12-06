# frozen_string_literal: true

module CrossRef
  class CommentSerializer < Jat
    config.auto_preload = false

    type :comment

    relationship :user,
                 exposed: true,
                 serializer: -> { CrossRef::UserSerializer }
  end
end
