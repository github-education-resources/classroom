module StarterCode
  extend ActiveSupport::Concern

  # rubocop:disable MethodLength
  def starter_code_repository_id(repo_name)
    return unless repo_name.present?

    if repo_name =~ %r{^[a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+$}
      begin
        github_repository = GitHubRepository.new(id: nil, access_token: current_user.access_token)
        github_repository.repository(full_name: repo_name).id
      rescue ArgumentError => err
        raise GitHub::Error, err.message
      end
    else
      raise GitHub::Error, 'Invalid repository name, use the format owner/name'
    end
  end
  # rubocop:enable MethodLength

  def validate_starter_code_repository_id(repo_id)
    if repo_id.is_a?(Integer) || (repo_id.is_a?(String) && repo_id =~ /^[0-9]+$/)
      begin
        GitHubRepository.new(id: repo_id.to_i, access_token: current_user.access_token).repository.id
      rescue ArgumentError => err
        raise GitHub::Error, err.message
      end
    else
      raise GitHub::Error, 'Invalid repository name, please check it again'
    end
  end
end
