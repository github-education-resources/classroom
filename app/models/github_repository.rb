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

  def latest_push_event
    github_event.latest_push_event(@id)
  end

  def commit_status(ref, **options)
    return nil unless ref.present?
    @client.combined_status(@id, ref, options)
  end

  def html_url_to(ref:)
    "#{html_url}/tree/#{ref}"
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

  def attributes
    %w(name full_name html_url)
  end

  def github_event
    @github_event ||= GitHub::Event.new(@client.access_token)
  end
end
