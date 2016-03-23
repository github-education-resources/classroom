class AutocompleteController < ApplicationController
  def github_repos
    @repos = search_github_repos(params[:query])

    respond_to do |format|
      format.html { render partial: 'autocomplete/repository_suggestions', locals: { repos: @repos } }
    end
  end

  private

  def required_scopes
    %w(repo)
  end

  def github_search_client
    @github_search_client ||= Octokit::Client.new(access_token: current_user.token, auto_paginate: false)
  end

  def search_github_repos(query)
    return github_search_client.repos(nil, sort: 'updated', per_page: 10, page: 1) unless query.present?

    keyword = query.gsub(%r{^[a-zA-Z0-9_-]+\/}, '') + ' in:name fork:true'

    # add namespace criteria if needed
    if query.include? '/'
      namespace = query.split('/').first
      keyword += " user:#{namespace}"
    end

    github_search_client.search_repos(keyword, per_page: 10, page: 1)[:items]
  end
end
