# frozen_string_literal: true

class AssignmentRepoView < SharedAssignmentRepoView
  include ActionView::Helpers::TextHelper
  attr_reader :assignment_repo

  delgate :github_user, to: :assignment_repo

  def avatar_url
    avatar_url_for(github_user, 96)
  end

  def user_login
    login_for(github_user)
  end

  def user_url
    user_url_for(github_user)
  end
end
