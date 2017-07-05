# frozen_string_literal: true

require 'safe_yaml/load'

class GitHubBlob
  # From jekyll/jekyll
  # https://github.com/jekyll/jekyll/blob/74373baa550282a8630368e7b609ca9370f6d560/lib/jekyll/document.rb#L13
  YAML_FRONT_MATTER_REGEXP = /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m

  attr_reader :data, :body

  def initialize(github_repository, sha, **options)
    repo = github_repository
    @blob = repo.client.blob(repo.full_name, sha, options)
    @data = nil
    @body = nil
    read_contents
  end

  # Get the utf-8 formated content of the blob
  #
  # Returns a string
  def utf_content
    decoded_content
  end

  # Get the content of the blob
  #
  # Returns a base64 string
  def content
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
