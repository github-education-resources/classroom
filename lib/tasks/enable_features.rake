# frozen_string_literal: true

task enable_features: :environment do
  GitHubClassroom.flipper[:team_management].enable_group :staff
  GitHubClassroom.flipper[:google_classroom_roster_import].enable_group :staff
  GitHubClassroom.flipper[:multiple_classrooms_per_org].enable_group :staff
  GitHubClassroom.flipper[:team_management].enable_group :staff
  GitHubClassroom.flipper[:search_assignments].enable_group :staff
  GitHubClassroom.flipper[:archive_classrooms].enable_group :staff
  GitHubClassroom.flipper[:lti_launch].enable_group :staff
  GitHubClassroom.flipper[:unified_repo_creators].enable_group :staff
  GitHubClassroom.flipper[:classroom_visibility].enable_group :staff
  GitHubClassroom.flipper[:template_repos].enable_group :staff
  GitHubClassroom.flipper[:student_identifier].enable_group :staff
end
