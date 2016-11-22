# frozen_string_literal: true
class GitHubRepository < GitHubResource
  def add_collaborator(collaborator, options = {})
    GitHub::Errors.with_error_handling do
      @client.add_collaborator(@id, collaborator, options)
    end
  end

  def get_starter_code_from(source)
    GitHub::Errors.with_error_handling do
      options = {
        accept:       Octokit::Preview::PREVIEW_TYPES[:source_imports],
        vcs_username: @client.login,
        vcs_password: @client.access_token
      }

      @client.start_source_import(@id, 'git', "https://github.com/#{source.full_name}", options)
    end
  end

  def present?(**options)
    self.class.present?(@client, @id, options)
  end

  def self.present?(client, full_name, **options)
    client.repository?(full_name, options)
  end

  def self.find_by_name_with_owner!(client, full_name)
    GitHub::Errors.with_error_handling do
      repository = client.repository(full_name)
      GitHubRepository.new(client, repository.id)
    end
  end

  private

  def github_attributes
    %w(name full_name html_url)
  end
end
