# frozen_string_literal: true

task enable_features: :environment do
  GitHubClassroom.flipper[:team_management].enable_group :staff
  GitHubClassroom.flipper[:repo_setup].enable_group :staff
end
