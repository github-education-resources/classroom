# frozen_string_literal: true
module GitHubClassroom
  module Scopes
    TEACHER                  = %w(user:email repo delete_repo admin:org).freeze
    GROUP_ASSIGNMENT_STUDENT = %w(admin:org user:email).freeze
    ASSIGNMENT_STUDENT       = %w(user:email).freeze

    module ExplicitAssignmentSubmission
      TEACHER = %w(user:email repo delete_repo admin:org admin:org_hook).freeze
    end
  end
end
