# frozen_string_literal: true

require "rails_helper"

describe GitHubBlob do
  let(:github_Repository) { classroom_org }

  before do
    Octokit.reset!
    @client = oauth_client

    # 25408465 is jekyll/example
    @github_repository = GitHubRepository.new(@client, 25_408_465)
  end

  it "retrieves repository specific blob", :vcr do
    # 8514 is rails/rails
    rails_github_repository = GitHubRepository.new(@client, 8514)

    # sha for jekyll/example/README.md
    blob_sha = "c5dd07b3c9f63dcf9864e289def55485514774de"
    github_blob = @github_repository.blob(blob_sha)

    expect do
      rails_github_repository.blob(blob_sha)
    end.to raise_error(GitHub::Error)

    expect(github_blob.content).not_to be_empty
  end

  it "parses yaml front matter", :vcr do
    # sha for jekyll/example/about.md
    blob_sha = "3ed64bb62b98b0827096cda5da5a728ec1bf5e3e"
    github_blob = @github_repository.blob(blob_sha)

    expect(github_blob.data).to have_key "title"
    expect(github_blob.data["title"]).to eq("About")
  end

  it "converts base64 to utf-8", :vcr do
    # sha for jekyll/example/README.md
    blob_sha = "c5dd07b3c9f63dcf9864e289def55485514774de"
    github_blob = @github_repository.blob(blob_sha)

    expect(github_blob.encoding).to eq("base64")
    expect(github_blob.content).not_to eq(github_blob.utf_content)
  end
end
