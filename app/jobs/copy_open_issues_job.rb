class CopyOpenIssuesJob < ActiveJob::Base
  queue_as :issue_copier

  def perform(user, source_repo_id, destination_repo_id)
    client = user.github_client
    GitHub::Errors.with_error_handling do
      source_issues = client.issues(source_repo_id, sort: 'created', direction: 'asc').reject(&:pull_request)
      source_issues.each do |issue|
        client.create_issue(destination_repo_id, issue.title, issue.body, labels: issue.labels.map(&:name))
      end
    end
  end
end
