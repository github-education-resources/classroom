# frozen_string_literal: true

task enable_features: :environment do
  GitHubClassroom.flipper[:archive_classrooms].enable_group :staff
  GitHubClassroom.flipper[:classroom_visibility].enable_group :staff
end
