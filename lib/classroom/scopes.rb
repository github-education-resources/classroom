# frozen_string_literal: true
module Classroom
  module Scopes
    TEACHER                  = %w(user:email repo delete_repo admin:org admin:org_hook).freeze
    GROUP_ASSIGNMENT_STUDENT = %w(repo admin:org user:email).freeze
    ASSIGNMENT_STUDENT       = %w(repo user:email).freeze
  end
end
