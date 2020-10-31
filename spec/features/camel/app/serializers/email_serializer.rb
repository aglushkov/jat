# frozen_string_literal: true

module Camel
  class EmailSerializer < Jat
    config.key_transform = :camel_lower

    type :email

    attribute :email
    attribute :old_email
  end
end
