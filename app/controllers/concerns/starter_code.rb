module StarterCode
  include GitHub
  extend ActiveSupport::Concern

  # rubocop:disable MethodLength
  def starter_code_repository_id(repo_name)
    return unless repo_name.present?

    if repo_name =~ %r{^[a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+$}
      begin
        github_repository = GitHubRepository.new(current_user.github_client, nil)
        github_repository.repository(repo_name).id
      rescue ArgumentError => err
        raise GitHub::Error, err.message
      end
    else
      raise GitHub::Error, 'Invalid repository name, use the format owner/name'
    end
  end
  # rubocop:enable MethodLength
end
