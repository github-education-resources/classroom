# frozen_string_literal: true

class AssignmentRepoView < SharedAssignmentRepoView
  include ActionView::Helpers::TextHelper
  attr_reader :assignment_repo

  def avatar_url
    @avatar_url ||= github_user.github_avatar_url(96)
  end

  def user_login
    @user_login ||= github_user.login
  end

  def user_url
    "https://github.com/#{user_login}"
  end

  def github_user
    assignment_repo.github_user
  end
end
