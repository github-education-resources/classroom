# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  attributes :id
  attributes :username

  def username
    object.github_user.login
  end
end
