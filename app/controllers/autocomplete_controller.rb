class AutocompleteController < ApplicationController
  def github_repos
    github_search = GitHub::Search.new(current_user.token, current_user.uid, auto_paginate: false)
    @repos        = github_search.search_github_repositories(params[:query])

    respond_to do |format|
      format.html { render partial: 'autocomplete/repository_suggestions', locals: { repos: @repos } }
    end
  end
end
