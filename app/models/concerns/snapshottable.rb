# frozen_string_literal: false
module Snapshottable
  extend ActiveSupport::Concern

  def create_github_repository_if_not_exists
    unless client.repository?(full_snapshot_repo_name, headers: GitHub::APIHeaders.no_cache_no_store)
      github_organization.create_repository(snapshot_repo_name,
                                            description: 'Snapshot repo created by GitHub Classroom.',
                                            auto_init: true)
    end
  end

  def github_organization
    @github_organization ||= GitHubOrganization.new(organization.github_client, organization.github_id)
  end

  def client
    organization.github_client
  end

  def snapshot_repo_name
    slugify
  end

  def snapshot_git_url
    "https://github.com/#{full_snapshot_repo_name}.git"
  end

  def full_snapshot_repo_name
    "#{github_organization.login}/#{slugify}"
  end

  def readme_file
    "## #{Time.zone.now.strftime('Snapshot created at %Y-%m-%d %I:%M:%S %Z %z')}\n\n"\
    "This is a snapshot containing all submissions of the assignment #{title} \n\n"\
    "**Please don't modify this snapshot manually.** \n\n"\
    "To clone this snapshot, please use the following command: \n"\
    "```\n"\
    "git clone --recursive #{snapshot_git_url}\n"\
    "```\n"
  end

  def gitmodules_file
    gitmodules_file_content = ''
    assignment_repos.each do |repo|
      gitmodules_file_content << "[submodule \"#{repo.repo_name}\"]\n"\
      "\tpath = #{repo.repo_name}\n"\
      "\turl = https://github.com/#{github_organization.login}/#{repo.repo_name}\n"
    end
    gitmodules_file_content
  end

  def submodules
    submodules = []
    assignment_repos.each do |repo|
      begin
        assignment_ref = client.ref("#{github_organization.login}/#{repo.repo_name}", 'heads/master')
      rescue Octokit::Conflict
        next
      end
      submodules.push(path: repo.repo_name, mode: '160000', type: 'commit', sha: assignment_ref[:object][:sha])
    end
    submodules
  end

  def git_objects
    git_objects = submodules
    gitmodules_blob = client.create_blob(full_snapshot_repo_name, gitmodules_file)
    readme_blob = client.create_blob(full_snapshot_repo_name, readme_file)
    git_objects.push(path: '.gitmodules', mode: '100644', type: 'blob', sha: gitmodules_blob)
    git_objects.push(path: 'README.md', mode: '100644', type: 'blob', sha: readme_blob)
    git_objects
  end

  def current_commit_sha
    @current_commit_sha ||= client.ref(full_snapshot_repo_name, 'heads/master')['object']['sha']
  end

  def commit_message
    Time.zone.now.strftime('Snapshot created at %Y-%m-%d %I:%M:%S %Z %z')
  end

  def create_commit
    tree = client.create_tree(full_snapshot_repo_name, git_objects)
    commit = client.create_commit(full_snapshot_repo_name, commit_message, tree.sha, current_commit_sha)
    client.update_ref(full_snapshot_repo_name, 'heads/master', commit.sha)
  end

  def create_snapshot
    create_github_repository_if_not_exists
    create_commit
  end
end
