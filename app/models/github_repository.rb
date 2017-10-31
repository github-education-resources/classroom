# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class GitHubRepository < GitHubResource
  depends_on :import

  DEFAULT_LABEL_COLOR = "ffffff"

  # NOTE: LEGACY, DO NOT REMOVE.
  # This is needed for the lib/collab_migration.rb
  def add_collaborator(collaborator, options = {})
    GitHub::Errors.with_error_handling do
      @client.add_collaborator(@id, collaborator, options)
    end
  end

  # Public: Invite a user to a GitHub repository.
  #
  # user - The String GitHub login for the user.
  #
  # Returns an Integer Invitation id, or raises a GitHub::Error.
  def invite(user, **options)
    GitHub::Errors.with_error_handling do
      options[:accept] = Octokit::Preview::PREVIEW_TYPES[:repository_invitations]
      @client.invite_user_to_repository(@id, user, options)
    end
  end

  # Public: Get all labels of a GitHub repository.
  #
  # Returns a list of labels
  def labels(options = {})
    GitHub::Errors.with_error_handling do
      @client.labels(full_name, options)
    end
  rescue GitHub::Error
    []
  end

  # Public: Add a label to a GitHub repository.
  #
  # label - The String name of the label.
  # color -  (defaults to: "ffffff")  A color, in hex, without the leading #
  #
  # Returns a Hash of the label, or raises a GitHub::Error.
  def create_label(label, color = DEFAULT_LABEL_COLOR, options = {})
    GitHub::Errors.with_error_handling do
      @client.add_label(full_name, label, color, options)
    end
  end

  # Public: Delete a label to a GitHub repository.
  #
  # label - The String name of the label.
  #
  # Returns nothing, or raises a GitHub::Error.
  def delete_label!(label, options = {})
    GitHub::Errors.with_error_handling do
      @client.delete_label!(full_name, label, options)
    end
  end

  # Public: Add issues to the GitHub repository.
  #
  # title    - The title of the issue.
  # body     - The body of the issue.
  #
  # options - optional params
  #          :assignee - User login.
  #          :milestone - Milestone number.
  #          :labels - List of comma separated Label names.
  #
  # Returns the newly created issue, or raises a GitHub::Error.
  def create_issue(title, body, **options)
    GitHub::Errors.with_error_handling do
      @client.create_issue(full_name, title, body, options)
    end
  end

  # Public: Get a tree object from the GitHub repository.
  #
  # sha    - sha of the tree.
  #
  # Returns a git Tree object, or empty hash.
  def tree(sha, **options)
    GitHub::Errors.with_error_handling do
      @client.tree(full_name, sha, options)
    end
  rescue GitHub::Error
    {}
  end

  # Public: Get a blob from the GitHub repository.
  #
  # sha    - The string sha value of the blob.
  #
  # Returns a GitHubBlob instance, or raises a GitHub::Error.
  def blob(sha, **options)
    GitHub::Errors.with_error_handling do
      @blob = GitHubBlob.new(self, sha, options)
    end
  end

  def default_branch
    GitHub::Errors.with_error_handling do
      repository = @client.repository(full_name)

      repository[:default_branch]
    end
  end

  def branch(name, **options)
    GitHub::Errors.with_error_handling do
      @client.branch(full_name, name, options)
    end
  rescue GitHub::Error
    {}
  end

  # Internal: Helper to get a tree's objects of a git tree
  #
  # tree_sha - The string sha of a git tree
  #
  # Returns a list of objects
  def tree_objects(tree_sha)
    git_tree = tree(tree_sha)
    return [] if git_tree.blank?
    git_tree.tree
  end

  def remove_branch(name, **options)
    GitHub::Errors.with_error_handling do
      @client.delete_branch(full_name, name, options)
    end
  end

  def commits(branch)
    GitHub::Errors.with_error_handling do
      @client.commits(full_name, sha: branch)
    end
  rescue GitHub::Error
    []
  end

  # The `commits` method paginates to 30 commits.
  # As an alternative, we fetch the contribution stats for the
  # top 100 contributors, then sum the commits.
  # This isn't perfect, but it's better than our current approach which
  # shows 30 commits for anything with more than 30 commits.
  def number_of_commits
    GitHub::Errors.with_error_handling do
      result = @client.contributors_stats(full_name, retry_timeout: 2)
      return 0 unless result

      result.sum do |user|
        user["total"]
      end
    end
  rescue GitHub::Error
    0
  end

  def commits_url(branch)
    html_url + "/commits/" + branch
  end

  def tree_url_for_sha(sha)
    html_url + "/tree/" + sha
  end

  # Public: Checks if the GitHub repository has a given branch.
  #
  # branch    - name of the branch to check for
  #
  # Returns true if branch exists, false otherwise
  def branch_present?(branch, **options)
    GitHub::Errors.with_error_handling do
      @client.branches(full_name, options).map(&:name).include? branch
    end
  rescue GitHub::Error
    false
  end

  def present?(**options)
    self.class.present?(@client, @id, options)
  end

  def public=(is_public)
    GitHub::Errors.with_error_handling do
      @client.update(full_name, private: !is_public)
    end
  end

  def self.present?(client, full_name, **options)
    GitHub::Errors.with_error_handling do
      client.repository?(full_name, options)
    end
  rescue GitHub::Error
    false
  end

  def self.find_by_name_with_owner!(client, full_name)
    GitHub::Errors.with_error_handling do
      repository = client.repository(full_name)
      GitHubRepository.new(client, repository.id)
    end
  end

  private

  def github_attributes
    %w[name full_name html_url]
  end
end
# rubocop:enable Metrics/ClassLength
