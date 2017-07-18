# frozen_string_literal: true

module Nameable
  extend ActiveSupport::Concern

  def generate_github_repo_name
    @suffix_number = 0

    loop do
      break unless GitHubRepository.present?(organization.github_client, full_name)
      @suffix_number += 1
    end

    suffixed_repo_name
  end

  private

  def base_name
    @base_name ||= "#{slug}-#{name}"
  end

  def full_name
    "#{organization_login}/#{suffixed_repo_name}"
  end

  def suffixed_repo_name
    return base_name if @suffix_number.zero?

    suffix = "-#{@suffix_number}"
    base_name.truncate(100 - suffix.length, omission: "") + suffix
  end

  def organization_login
    @organization_login ||= organization.github_organization.login_no_cache
  end
end
