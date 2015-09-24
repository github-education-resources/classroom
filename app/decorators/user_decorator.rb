class UserDecorator < Draper::Decorator
  delegate_all

  def avatar_url(size)
    "https://avatars.githubusercontent.com/u/#{uid}?v=3&size=#{size}"
  end

  def github_url
    github_user.html_url
  end

  def login
    github_user.login
  end

  private

  def github_user
    @github_user ||= GitHubUser.new(github_client, uid).user
  rescue GitHub::NotFound
    NullGitHubUser
  end
end
