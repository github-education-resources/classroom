# frozen_string_literal: true

module AvatarHelper
  def github_avatar_url(id, size)
    "https://avatars.githubusercontent.com/u/#{id}?v=3&size=#{size}"
  end
end
