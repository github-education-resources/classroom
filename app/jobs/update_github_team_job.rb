class UpdateGithubTeamJob < ActiveJob::Base
  queue_as :default

  def perform(user_id, team_id, options)
    user = User.find(user_id)

    if user
      @team = user.github_client.update_team(team_id, options)
    end
  end
end
