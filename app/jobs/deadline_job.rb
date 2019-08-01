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

  # we explicitly rescue Octokit::InvalidRepository because
  # it is not inherited from Octokit::Error so it is not
  # handled by our GitHub::Error.with_error_handling block
  # for more info see:
  # https://github.com/octokit/octokit.rb/blob/master/lib/octokit/error.rb#L310
  rescue Octokit::InvalidRepository => e
    log_error(repo, e)
  rescue ActiveRecord::ActiveRecordError => e
    log_error(repo, e)
  end

  def log_error(repo, error)
    logger.error(repo)
    logger.error(error)
  end
end
