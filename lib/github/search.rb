# frozen_string_literal: true

module GitHub
  class Search
    REPOSITORY_REGEX = /[a-zA-Z0-9\._-]+/
    USERNAME_REGEX = /[a-zA-Z0-9_-]+/

    attr_accessor :search_client

    def initialize(access_token, options = { auto_paginate: false })
      options[:access_token] = access_token

      @search_client = Octokit::Client.new(options)
    end

    def search_github_repositories(query, options = { sort: "updated", per_page: 10, page: 1 })
      return [], "" if query.blank?

      return GitHub::Errors.with_error_handling do
        search_query = build_github_repositories_query(query)
        search_client.search_repos(search_query, options)[:items]
      end, ""
    rescue GitHub::Error => err
      return [], err.message
    end

    private

    def build_github_repositories_query(query)
      keyword = query.gsub(%r{^#{REPOSITORY_REGEX}\/}, "") + " in:name fork:true"

      # add namespace criteria if needed
      return keyword unless query.include?("/")

      namespace = query.split("/").first
      "#{keyword} user:#{namespace}"
    end
  end
end
