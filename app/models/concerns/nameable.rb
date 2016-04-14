# frozen_string_literal: true
module Nameable
  extend ActiveSupport::Concern

  def github_repo_name(assignment_slug, user_login)
    suffix_number = 0
    suffix_number += 1 while
        GitHubRepository.present?(organization.github_client, full_name(assignment_slug, user_login, suffix_number))
    suffixed_repo_name(assignment_slug, user_login, suffix_number)
  end

  def full_name(assignment_slug, user_login, suffix_number)
    "#{organization.decorate.login}/#{suffixed_repo_name(assignment_slug, user_login, suffix_number)}"
  end

  def suffixed_repo_name(assignment_slug, user_login, suffix_number)
    base_name = "#{assignment_slug}-#{user_login}"
    return base_name if suffix_number.zero?
    suffix = suffix_number.to_s
    "#{base_name[0, 99 - suffix.length]}-#{suffix}"
  end
end
