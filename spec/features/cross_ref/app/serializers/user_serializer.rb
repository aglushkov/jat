# frozen_string_literal: true

module CrossRef
  class UserSerializer < Jat
    config.auto_preload = false

    type :user

    attribute :id
    relationship :comments,
                 exposed: true,
                 serializer: -> { CrossRef::CommentSerializer },
                 many: true
  end
end
