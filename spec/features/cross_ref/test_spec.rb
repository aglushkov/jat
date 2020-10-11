# frozen_string_literal: true

##
# Test case when:
# - User has many Comments
# - Comments have one User
#
RSpec.describe 'Cross reference of serializers' do
  require_relative './app/models/user'
  require_relative './app/models/comment'
  require_relative './app/serializers/user_serializer'
  require_relative './app/serializers/comment_serializer'

  let(:user) do
    CrossRef::User.new
  end

  let(:comment) do
    CrossRef::Comment.new
  end

  before do
    user.id = 1
    user.comments = [comment]

    comment.id = 1
    comment.user = user
  end

  it 'serializes when referenced param in not exposed' do
    CrossRef::CommentSerializer.relationship(
      :user,
      serializer: CrossRef::UserSerializer, exposed: false
    )

    serializer = CrossRef::UserSerializer.new

    expect { serializer.to_h(user, many: false) }.not_to raise_error
  end

  it 'serializes when fields make cross referenced param not exposed' do
    CrossRef::CommentSerializer.relationship(
      :user,
      serializer: -> { CrossRef::UserSerializer }, exposed: true
    )

    params = { fields: { user: 'comments' } }
    serializer = CrossRef::UserSerializer.new(params)

    expect { serializer.to_h(user, many: false) }.not_to raise_error
  end

  it 'raises error and shows what objects have cross references'
end
