# frozen_string_literal: true

class DeadlineJob < ApplicationJob
  queue_as :deadline

  def perform(deadline_id)
    deadline = Deadline.find_by(id: deadline_id)
    return unless deadline

    deadline.assignment.repos.each do |repo|
      fetch_submission_sha(repo)
    end
  end

  def fetch_submission_sha(repo)
    commit_list = repo.commits(repo.default_branch)
    latest_commit = commit_list.try(:first)

    return unless latest_commit

    repo.submission_sha = latest_commit[:sha]
    repo.save!
  rescue ActiveRecord::ActiveRecordError => e
    logger.error(repo)
    logger.error(e)
  end
end
