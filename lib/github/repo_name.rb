module GitHub
  class RepoName
    attr_accessor :search_client

    def initialize(organization, user, assignment)
      @organization = organization
      @user = user
      @assignment = assignment

      @suffix_number = 0
      @suffix_number += 1 while repository?
    end

    def repository?
      @organization.github_client.repository?("#{@organization.decorate.login}/#{repo_name}")
    end

    def repo_name
      base_name = "#{@assignment.slug}-#{@user.decorate.login}"
      return base_name if @suffix_number.zero?
      suffix = @suffix_number.to_s
      "#{base_name[0, 99 - suffix.length]}-#{suffix}"
    end
  end
end
