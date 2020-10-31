# frozen_string_literal: true

RSpec.describe 'Camelizing keys' do
  require_relative './app/models/user'
  require_relative './app/models/email'
  require_relative './app/serializers/user_serializer'
  require_relative './app/serializers/email_serializer'

  let(:user) do
    Camel::User.new
  end

  let(:email) do
    Camel::Email.new
  end

  before do
    user.id = 1
    user.first_name = 'First Name'
    user.email = email

    email.id = 1
    email.email = 'Email'
    email.old_email = 'Old Email'
  end

  it 'serializes correctly' do
    serializer = Camel::UserSerializer.new
    result = serializer.to_h(user)

    expect(result).to eq(
      data: {
        type: :user, id: 1,
        attributes: { firstName: 'First Name' },
        relationships: {
          confirmedEmail: { data: { type: :email, id: 1 } }
        }
      },
      included: [
        {
          type: :email, id: 1,
          attributes: { email: 'Email', oldEmail: 'Old Email' }
        }
      ]
    )
  end
end
