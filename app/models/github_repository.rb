# frozen_string_literal: true
class GitHubRepository
  attr_reader :id

  def initialize(client, id)
    @client = client
    @id     = id
  end

  # Public
  #
  def add_collaborator(collaborator)
    GitHub::Errors.with_error_handling do
      @client.add_collaborator(@id, collaborator)
    end
  end

  # Public
  #
  def full_name
    GitHub::Errors.with_error_handling { @client.repository(@id).full_name }
  end

  # Public
  #
  def get_starter_code_from(source)
    GitHub::Errors.with_error_handling do
      credentials = { vcs_username: @client.login, vcs_password: @client.access_token }
      @client.start_source_import(@id, 'git', "https://github.com/#{source.full_name}", credentials)
    end
  end

  # Public
  #
  def self.present?(client, full_name)
    client.repository?(full_name)
  end

  # Public
  #
  def repository(full_repo_name = nil)
    GitHub::Errors.with_error_handling do
      @client.repository(full_repo_name || @id)
    end
  end
end
