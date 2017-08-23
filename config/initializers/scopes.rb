# frozen_string_literal: true

module GitHubClassroom
  module Scopes
    TEACHER                  = %w[user:email repo:status repo_deployment
                                  public_repo delete_repo write:org read:org admin:org_hook].freeze
    GROUP_ASSIGNMENT_STUDENT = %w[write:org read:org user:email].freeze
    ASSIGNMENT_STUDENT       = %w[user:email repo:invite].freeze
  end
end
