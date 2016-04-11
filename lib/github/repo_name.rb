module GitHub
  class RepoName
    attr_accessor :search_client

    def initialize(client, organization_login, user_login, assignment_slug)
      @client = client
      @organization_login = organization_login
      @user_login = user_login
      @assignment_slug = assignment_slug

      @suffix_number = 0
      @suffix_number += 1 while repository?
    end

    def repository?
      @client.repository?("#{@organization_login}/#{repo_name}")
    end

    def repo_name
      base_name = "#{@assignment_slug}-#{@user_login}"
      return base_name if @suffix_number.zero?
      suffix = @suffix_number.to_s
      "#{base_name[0, 99 - suffix.length]}-#{suffix}"
    end
  end
end
