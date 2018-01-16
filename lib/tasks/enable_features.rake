# frozen_string_literal: true

task enable_features: :environment do
  User.all.each do |user|
    if user.staff?
      GitHubClassroom.flipper[:team_managment].enable
      GitHubClassroom.flipper[:repo_setup].enable
      GitHubClassroom.flipper[:student_identifier].enable
    end
  end
end
