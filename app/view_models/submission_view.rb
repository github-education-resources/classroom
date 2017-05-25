# frozen_string_literal: true

class SubmissionView < ViewModel
  attr_reader :repo

  def submission_failed?
    submission_passed? && repo.submission_sha.blank?
  end

  def submission_succeeded?
    submission_passed? && repo.submission_sha.present?
  end

  def submission_passed?
    repo.assignment.deadline&.passed?
  end

  def submission_url
    return unless submission_succeeded?

    repo.github_repository.tree_url_for_sha(repo.submission_sha)
  end
end
