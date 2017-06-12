# frozen_string_literal: true

class GitHubRepository < GitHubResource
  # NOTE: LEGACY, DO NOT REMOVE.
  # This is needed for the lib/collab_migration.rb
  def add_collaborator(collaborator, options = {})
    GitHub::Errors.with_error_handling do
      @client.add_collaborator(@id, collaborator, options)
    end
  end

  def get_starter_code_from(source)
    GitHub::Errors.with_error_handling do
      options = {
        vcs:          'git',
        accept:       Octokit::Preview::PREVIEW_TYPES[:source_imports],
        vcs_username: @client.login,
        vcs_password: @client.access_token
      }

      @client.start_source_import(@id, "https://github.com/#{source.full_name}", options)
    end
  end

  # Public: Invite a user to a GitHub repository.
  #
  # user - The String GitHub login for the user.
  #
  # Returns an Integer Invitation id, or raises a GitHub::Error.
  def invite(user, **options)
    GitHub::Errors.with_error_handling do
      options[:accept] = Octokit::Preview::PREVIEW_TYPES[:repository_invitations]
      @client.invite_user_to_repository(@id, user, options)
    end
  end

  def default_branch
    GitHub::Errors.with_error_handling do
      repository = @client.repository(full_name)

      repository[:default_branch]
    end
  end

  def commits(branch)
    GitHub::Errors.with_error_handling do
      @client.commits(full_name, sha: branch)
    end
  rescue GitHub::Error
    []
  end

  def tree_url_for_sha(sha)
    html_url + '/tree/' + sha
  end

  def present?(**options)
    self.class.present?(@client, @id, options)
  end

  def public=(is_public)
    GitHub::Errors.with_error_handling do
      @client.update(full_name, private: !is_public)
    end
  end

  def self.present?(client, full_name, **options)
    GitHub::Errors.with_error_handling do
      client.repository?(full_name, options)
    end
  rescue GitHub::Error
    false
  end

  def self.find_by_name_with_owner!(client, full_name)
    GitHub::Errors.with_error_handling do
      repository = client.repository(full_name)
      GitHubRepository.new(client, repository.id)
    end
  end

  private

  def github_attributes
    %w[name full_name html_url]
  end
end
