# frozen_string_literal: true

module Camel
  class UserSerializer < Jat
    config.key_transform = :camelLower

    type :user

    attribute :first_name

    relationship :confirmed_email,
                 exposed: true,
                 serializer: -> { Camel::EmailSerializer },
                 delegate: false

    def confirmed_email(user, _params)
      user.email
    end
  end
end
