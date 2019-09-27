# frozen_string_literal: true

module UnlinkedUser
  class ShowView < ViewModel
    attr_reader :unlinked_user

    def github_handle_text
      "@" + unlinked_user.github_user.login
    end

    def github_avatar_url
      unlinked_user.github_user.github_avatar_url(96)
    end

    def github_url
      unlinked_user.github_user.html_url
    end
  end
end
