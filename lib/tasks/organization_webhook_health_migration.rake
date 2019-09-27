# frozen_string_literal: true

namespace :organization_webhook_health_migration do
  desc "Ensures that every OrganizationWebhook has a working webhook, otherwise records the failure"
  task migrate_orgs_with_missing_records: :environment do
    OrganizationWebhookHealthService.perform_and_print
  end

  task migrate_all: :environment do
    OrganizationWebhookHealthService.perform_and_print(all_organizations: true)
  end
end
