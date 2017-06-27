# frozen_string_literal: true

require 'safe_yaml/load'

class GitHubBlob
  YAML_FRONT_MATTER_REGEXP = %r!\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)!m

  attr_reader :data, :body

  def initialize(github_repository, sha, **options)
    repo = github_repository
    @blob = repo.client.blob(repo.full_name, sha, options)
    @data = nil
    @body = nil
    read_contents
  end

  def utf_content
    # return utf-8 encoded version of blob binary
    decoded_content
  end

  def content
    # return base64 content
    @blob.content
  end

  private

  def decoded_content
    return @blob.content unless @blob.content != 'utf-8'
    Base64.decode64(@blob.content)
  end

  def read_contents
    match = YAML_FRONT_MATTER_REGEXP.match(decoded_content)
    if match
      @body = match.post_match
      @data = SafeYAML.load(match.to_s)
    end
    @data
  end
end
