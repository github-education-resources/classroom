# frozen_string_literal: true

module Invitation
  class SuccessView < ViewModel
    attr_reader :submission

    # Public: Determine if the submission is for an
    # individual or a group.
    def assignment_submission?
      submission.is_a?(AssignmentInvitation)
    end

    def github_organization
      return @github_organization if defined?(@github_organization)
      @github_organization = current_assignment.organization.github_organization
    end

    def github_repository
      return @github_repository if defined?(@github_repository)
      @github_repository = current_assignment.organization.github_organization
    end

    def title
      return @title if defined?(@title)
      @title = current_assignment.title
    end

    private

    def current_assignment
      return @current_assignment if defined?(@current_assignment)
      @current_assignment = submission.try(:assignment) || submission.try(:group_assignment)
    end
  end
end
