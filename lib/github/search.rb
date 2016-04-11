module GitHub
  class Search
    attr_accessor :search_client

    def initialize(access_token, github_id, options = { auto_paginate: false })
      options[:access_token] = access_token

      @github_id = github_id
      @search_client = Octokit::Client.new(options)
    end

    def search_github_repositories(query, options = { sort: 'updated', per_page: 10, page: 1 })
      return GitHub::Errors.with_error_handling do
        if query.present?
          search_query = build_github_repositories_query(query)
          search_client.search_repos(search_query, options)[:items]
        else
          search_client.repos(@github_id, options)
        end
      end, ''
    rescue GitHub::Error => err
      return [], err.message
    end

    private

    def build_github_repositories_query(query)
      keyword = query.gsub(%r{^[a-zA-Z0-9_-]+\/}, '') + ' in:name fork:true'

      # add namespace criteria if needed
      return keyword unless query.include?('/')

      namespace = query.split('/').first
      "#{keyword} user:#{namespace}"
    end
  end
end
