# frozen_string_literal: true

module Camel
  class EmailSerializer < Jat
    config.auto_preload = false
    config.key_transform = :camelLower

    type :email

    attribute :id
    attribute :email
    attribute :old_email
  end
end
