# frozen_string_literal: true

module Camel
  class UserSerializer < Jat
    config.auto_preload = false
    config.key_transform = :camelLower

    type :user

    attribute :id
    attribute :first_name

    relationship :confirmed_email,
                 key: :email,
                 exposed: true,
                 serializer: -> { Camel::EmailSerializer }
  end
end
