# frozen_string_literal: true

require "ruby-progressbar"

namespace :organization_default_repository_permission do
  desc "Migrate all Organizations to have default repository permission 'none'"
  task migrate: :environment do
    progress_bar = ProgressBar.create(
      title: "Iterating over Organizations",
      starting_at: 0,
      total: Organization.count,
      format: "%t: %a %e %c/%C (%j%%) %R |%B|",
      throttle_rate: 0.5,
      output: Rails.env.test? ? StringIO.new : STDERR
    )

    Organization.includes(:users).find_in_batches(batch_size: 500) do |orgs|
      orgs.each do |org|
        result = OrganizationDefaultRepositoryPermissionMigrator.perform(organization: org)
        puts result.error if result.failed?
        progress_bar.increment
      end
    end
  end
end
