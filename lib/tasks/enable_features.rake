# frozen_string_literal: true

task enable_features: :environment do
  GitHubClassroom.flipper[:team_management].enable_group :staff
  GitHubClassroom.flipper[:archive_classrooms].enable_group :staff
  GitHubClassroom.flipper[:classroom_visibility].enable_group :staff
end
