# frozen_string_literal: true

# Parent class to hold id and organization id attributes.
# Used for defining GitHub resources that are dependant on an id and a organization id.
class GitHubOrgResource < GitHubModel
  attr_reader :org_id, :id

  # client  - The Octokit::Client making the request.
  # org_id  - The Interger organization id for the resource.
  # id      - The Interger id for the resource.
  # options - A Hash of options to pass (optional).
  #
  def initialize(client, org_id, id, **options)
    super(client, { org_id: org_id, id: id }, options)
  end

  private

  def github_attributes
    []
  end

  def local_cached_attributes
    []
  end
end
