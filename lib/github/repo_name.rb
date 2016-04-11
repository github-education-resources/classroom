module GitHub
  class RepoName
    attr_accessor :search_client

    def initialize(user_login, assignment, github_organization_login)
      @user_login = user_login
      @assignment = assignment
      @github_organization_login = github_organization_login
      @repo_name_client = Octokit::Client.new()
      assign_suffix
    end

    def repository?
      pp "#{@organization.login}/#{repo_name}"
      exist = @repo_name_client.repository?("#{@organization.login}/#{repo_name}")
      pp exist
      return exist
    end

    def assign_suffix
      @suffix = 0
      while repository?
        @suffix += 1
      end
    end

    def repo_name_base
      "#{@assignment.slug}-#{@user.login(headers: GitHub::APIHeaders.no_cache_no_store)}"
    end

    def repo_name
      return repo_name_base if @suffix == 0
      "#{repo_name_base}-#{@suffix}"
    end
  end
end