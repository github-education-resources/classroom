# frozen_string_literal: true

task enable_features: :environment do
  GitHubClassroom.flipper[:team_managment].enable_group :staff
  GitHubClassroom.flipper[:repo_setup].enable_group :staff
  GitHubClassroom.flipper[:student_identifier].enable_group :staff
end
