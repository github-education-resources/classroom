class AutocompleteController < ApplicationController
  def github_repos
    github_search          = GitHub::Search.new(current_user.token, current_user.uid, auto_paginate: false)
    results, error_message = github_search.search_github_repositories(params[:query])

    respond_to do |format|
      format.html do
        render partial: 'autocomplete/repository_suggestions', locals: { repos: results, error_message: error_message }
      end
    end
  end
end
