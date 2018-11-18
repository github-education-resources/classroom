# frozen_string_literal: true

# A parent class so that we always have the `id`, `client`, `access_token`,
# and an optional `org_id` attr_readers.

class GitHubResource < GitHubModel
  attr_reader :id, :client, :access_token, :org_id

  private

  def github_attributes
    []
  end
end
