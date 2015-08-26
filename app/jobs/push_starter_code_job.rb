class PushStarterCodeJob < ActiveJob::Base
  queue_as :starter_code

  def perform(assignment_repository_id, starter_code_repository_id)
    assignment_repository   = GitHubRepository.new(creator.github_client, assignment_repository_id)
    starter_code_repository = GitHubRepository.new(creator.github_client, starter_code_repository_id)

    assignment_repository.get_starter_code_from(starter_code_repository.full_name)
  end
end
