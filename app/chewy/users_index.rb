class UsersIndex < Chewy::Index
  define_type User do
    field :id
    field :uid

    field :avatar_url, value: (lambda do |user|
      begin
        GitHubUser.new(user.github_client, user.uid).user.avatar_url
      rescue GitHub::Forbidden, GitHub::NotFound
        "https://avatars0.githubusercontent.com/u/#{user.uid}?v=3"
      end
    end)

    field :html_url, value: (lambda do |user|
      begin
        GitHubUser.new(user.github_client, user.uid).user.html_url
      rescue GitHub::Forbidden, GitHub::NotFound
        NullGitHubUser.new.html_url
      end
    end)

    field :login, value: (lambda do |user|
      begin
        GitHubUser.new(user.github_client, user.uid).login
      rescue GitHub::Forbidden, GitHub::NotFound
        NullGitHubUser.new.login
      end
    end)

    field :name, value: (lambda do |user|
      begin
        GitHubUser.new(user.github_client, user.uid).user.name
      rescue GitHub::Forbidden, GitHub::NotFound
        NullGitHubUser.new.name
      end
    end)
  end
end
