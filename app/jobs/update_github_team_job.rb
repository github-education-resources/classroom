class UpdateGithubTeamJob < ActiveJob::Base
  queue_as :default

  def perform(user, team_id, options)
    user.github_client.update_team(team_id, options)
  end
end
