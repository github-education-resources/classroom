module GitHub
  module URL
    def self.avatar(id:, size:)
      "https://avatars.githubusercontent.com/u/#{id}?v=3&size=#{size}"
    end

    def self.github_team(github_organization:, github_team:)
      "https://github.com/orgs/#{github_organization.login}/teams/#{github_team.slug}"
    end

    def self.github_organization_team_invitation(github_organization:)
      "https://github.com/orgs/#{github_organization.login}/invitations/new"
    end
  end
end
