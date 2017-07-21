# frozen_string_literal: true

require_relative "vcr"

class StubRepository
  attr_reader :full_name, :branches

  def repo_file(repo_name, path)
    File.read(Rails.root.join("spec/fixtures/repos/#{repo_name}", path.to_s))
  end

  def repo_json(repo_name, path)
    JSON.parse(repo_file(repo_name, path), object_class: OpenStruct)
  end

  class Tree
    attr_reader :sha, :url, :tree, :truncated

    def initialize(repo, sha)
      tree_json = repo.repo_json(repo.full_name, sha)
      @sha       = tree_json.sha
      @url       = tree_json.url
      @tree      = tree_json.tree || []
      @truncated = tree_json.truncated
    end
  end

  class Blob
    attr_reader :data, :body, :utf_content

    def initialize(repo, sha)
      file_blob = repo.repo_file(repo.full_name, sha)
      @utf_content = file_blob
      read_contents
    end

    private

    def read_contents
      match = GitHubBlob::YAML_FRONT_MATTER_REGEXP.match(utf_content)
      return unless match
      @body = match.post_match
      @data = YAML.safe_load(match.to_s)
    end
  end

  def initialize(full_name)
    @full_name = full_name
    @branches = repo_json(full_name, "branches.json") || []
  end

  def import_progress
    repo_json(full_name, "import_progress.json")
  end

  def branch_present?(name)
    @branches.map(&:name).include? name
  end

  def branch(name)
    return {} unless branch_present? name
    @branches.select { |b| b.name == name }.last
  end

  def branch_tree(name)
    return {} unless branch_present? name
    Tree.new(self, branch(name).commit.sha)
  end

  def tree(sha)
    Tree.new(self, sha)
  end

  def blob(sha)
    Blob.new(self, sha)
  end
end

module RepositoryFactory
  def stub_repository(full_name)
    StubRepository.new(full_name)
  end

  def create_github_branch(client, repo, branch)
    client.create_contents(repo.full_name,
                           "README.md",
                           "Add README.md",
                           "Hello world GitHub Classroom",
                           branch: branch)
  end
end
