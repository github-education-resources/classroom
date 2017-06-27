# frozen_string_literal: true

class GitHubBlob
  def initialize(github_repository, sha, **options)
    repo = github_repository
    @blob = repo.client.blob(repo.full_name, sha, options)
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
end
