# frozen_string_literal: true

# Parent class to hold id attribute.
# Used for defining GitHub resources that are only dependant on an id.
class GitHubResource < GitHubModel
  attr_reader :id

  # client  - The Octokit::Client making the request.
  # id      - The Interger id for the resource.
  # options - A Hash of options to pass (optional).
  #
  def initialize(client, id, **options)
    super(client, { id: id }, options)
  end

  private

  def github_attributes
    []
  end

  def local_cached_attributes
    []
  end
end
