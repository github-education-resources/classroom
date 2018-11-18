# frozen_string_literal: true

# A parent class so that we always have the `org_id`, `id`, `client`,
# and `access_token` attr_readers.

class GitHubOrgResource < GitHubModel
  attr_reader :org_id, :id

  def initialize(client, org_id, id)
    super(client, { org_id: org_id, id: id })
  end

  private

  def github_attributes
    []
  end
end
