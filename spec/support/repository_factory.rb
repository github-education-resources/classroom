# frozen_string_literal: true

require_relative "vcr"
require "digest"

class StubRepository
  attr_reader :full_name, :branches

  def file(path)
    File.read(path.to_s)
  end

  def json_file(path)
    JSON.parse(file(path), object_class: OpenStruct)
  end

  class Blob
    attr_reader :data, :body, :encoding, :utf_content

    def initialize(repo, path)
      file_blob    = repo.file(path)
      @utf_content = file_blob
      @encoding    = "utf-8"
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
    @heads     = head_refs
    @branches  = branch_names
    @trees     = {}
    @blobs     = {}

    generate_git_objects
  end

  def import_progress
    import_json_path = repo_path + "/.git_/import_progress.json"
    return nil unless File.exist? import_json_path
    json_file(import_json_path)
  end

  def branch_present?(name)
    @branches.include? name
  end

  def branch(name)
    return {} unless head == name
    @trees[head_sha]
  end

  def tree_objects(tree_sha)
    git_tree = tree(tree_sha)
    return [] if git_tree.blank?
    git_tree.tree
  end

  def tree(sha)
    @trees[sha]
  end

  def blob(sha)
    @blobs[sha]
  end

  def present?(**_options)
    true
  end

  def importing?
    GitHubRepository::IMPORT_ONGOING.include? import_progress[:status]
  end

  def imported?
    import_progress[:status] == "complete"
  end

  def import_failed?
    GitHubRepository::IMPORT_ERRORS.include? import_progress[:status]
  end

  private

  def branch_names
    @heads.map { |h| h.split("refs/heads/").second }
  end

  # Internal: Add the head branch's tree to StubRepository trees
  #
  def generate_head_objects
    @trees[head_sha] ||= OpenStruct.new(sha: head_sha, url: repo_path, tree: sub_objects(repo_path),
                                        truncated: false, commit: OpenStruct.new(sha: head_sha))
  end

  # Internal: Add all repo trees to StubRepository trees
  #
  def generate_git_objects
    generate_head_objects
    Dir.glob(repo_path + "/**/*/").each do |t|
      tree_sha = Digest::SHA2.hexdigest(t)
      @trees[tree_sha] ||= OpenStruct.new(path: t.split("/").last, mode: "040000", type: "tree",
                                          sha: tree_sha, size: 0, url: t, tree: sub_objects(t))
    end
  end

  # Internal: Get all git objects (trees and blobs) from a given path
  #
  # Returns a list of git objects
  def sub_objects(path)
    tree = []
    Dir.glob(path.to_s + "/*").each do |t|
      t += "/" if File.directory?(t)
      tree << git_object(t)
    end
    tree
  end

  # Internal: Get git object (tree or blob) using a given path
  #
  # path - The path to the git object
  #
  # Returns a git object (As an OpenStruct instance)
  def git_object(path)
    object_sha = Digest::SHA2.hexdigest(path.to_s)
    @blobs[object_sha] ||= Blob.new(self, path) unless File.directory?(path)
    OpenStruct.new(path: path.split("/").last, mode: File.directory?(path) ? "tree" : "blob",
                   type: File.directory?(path) ? "040000" : "100644", sha: object_sha, size: 0, url: path)
  end

  def head
    file(repo_path + "/.git_/HEAD").strip.split("refs/heads/").second.to_s
  end

  def head_sha
    Digest::SHA2.hexdigest repo_path + head
  end

  def head_refs
    Dir.glob(repo_path + "/.git_/refs/**/*").reject { |f| File.directory?(f) }
       .map { |f| f.split(".git_/").second }
  end

  def repo_path
    Rails.root.to_s + "/spec/fixtures/repos/#{full_name}"
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
