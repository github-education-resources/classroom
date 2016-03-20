class AutocompleteController < ApplicationController
  def search_repos
    query = params[:query]
    if query.present?
      @repos = search_github_repos(query)
    else
      # default: current user, last updated first
      @repos = current_user.github_search_client.repos(nil, sort: 'updated', per_page: 10, page: 1)
    end
    respond_to do |format|
      format.html { render partial: 'autocomplete/repository_suggestions', locals: { repos: @repos } }
    end
  end

  private

  def search_github_repos(query)
    # query names only, including forked repos
    keyword = query.gsub(%r{^[a-zA-Z0-9_-]+\/}, '') + ' in:name fork:true'

    # add namespace criteria if needed
    if query.include? '/'
      namespace = query.split('/').first
      keyword += " user:#{namespace}"
    end
    current_user.github_search_client.search_repos(keyword, per_page: 10, page: 1)[:items]
  end
end
