# frozen_string_literal: true

class GitHubBlob
  # From jekyll/jekyll
  # https://github.com/jekyll/jekyll/blob/74373baa550282a8630368e7b609ca9370f6d560/lib/jekyll/document.rb#L13
  YAML_FRONT_MATTER_REGEXP = /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m

  attr_reader :data, :body, :encoding

  def initialize(github_repository, sha, **options)
    @blob = github_repository.client.blob(github_repository.full_name, sha, options)
    @encoding = @blob.encoding
    read_contents
  end

  # Public: Get the utf-8 formated content of the blob
  #
  # Returns a string.
  def utf_content
    return @blob.content if @encoding == "utf-8"
    Base64.decode64(@blob.content)
  end

  # Public: Get the content of the blob
  #
  # Returns a base64 string.
  def content
    @blob.content
  end

  private

  # Internal: process yaml front matter
  #
  # Returns nothing.
  def read_contents
    match = YAML_FRONT_MATTER_REGEXP.match(utf_content)
    return unless match
    @body = match.post_match
    @data = YAML.safe_load(match.to_s)
  end
end
