# frozen_string_literal: true

module GitHubClassroom
  module Scopes
    TEACHER                  = %w[user:email repo delete_repo admin:org admin:org_hook].freeze
    GROUP_ASSIGNMENT_STUDENT = %w[admin:org user:email repo:invite].freeze
    ASSIGNMENT_STUDENT       = %w[user:email repo:invite].freeze
  end
end
