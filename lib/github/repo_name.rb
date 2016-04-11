module GitHub
  class RepoName
    attr_accessor :search_client

    def initialize(user_login, assignment_slug, github_organization_login)
      @user_login = user_login
      @assignment_slug = assignment_slug
      @github_organization_login = github_organization_login
      @repo_name_client = Octokit::Client.new
      @suffix = 0
      @suffix +=1 while repository?
    end

    def repository?
      @repo_name_client.repository?("#{@github_organization_login}/#{repo_name}")
    end

    def repo_name_base
      "#{@assignment_slug}-#{@user_login}"
    end

    def repo_name
      return repo_name_base if @suffix.zero?
      "#{repo_name_base}-#{@suffix}"
    end
  end
end
