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

  it 'serializes when fields make cross referenced param not exposed' do
    params = { fields: { comment: 'user', user: '' } }
    serializer = CrossRef::CommentSerializer.new(params)
    expect { serializer.to_h(comment, many: false) }.not_to raise_error

    params = { fields: { user: 'comments', comment: '' } }
    serializer = CrossRef::UserSerializer.new(params)
    expect { serializer.to_h(user, many: false) }.not_to raise_error
  end
end
