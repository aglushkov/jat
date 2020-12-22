# frozen_string_literal: true

module CrossRef
  class CommentSerializer < Jat
    config.auto_preload = false

    type :comment

    attribute :id
    relationship :user,
                 exposed: true,
                 serializer: -> { CrossRef::UserSerializer }
  end
end
