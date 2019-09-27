# frozen_string_literal: true

module AssignmentRepoView
  class ShowView < SharedAssignmentRepoView
    attr_reader :assignment_repo

    delegate :github_user, to: :assignment_repo

    def github_avatar_url
      github_avatar_url_for(github_user, 96)
    end

    def github_user_login
      github_login_for(github_user)
    end

    def github_user_url
      github_user_url_for(github_user)
    end
  end
end
