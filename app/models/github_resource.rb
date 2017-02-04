# frozen_string_literal: true

# A parent class so that we always have
# the `id`, `client`, and `access_token`
# attr_readers.

class GitHubResource < GitHubModel
  attr_reader :id, :client, :access_token

  private

  def github_attributes
    []
  end
end
