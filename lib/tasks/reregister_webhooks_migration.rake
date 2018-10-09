# frozen_string_literal: true

task reregister_webhooks_migration: :environment do
  organizations_touched = 0
  Organization.find_in_batches(batch_size: 500) do |organizations_batch|
    organizations_batch.each do |organization|
      begin
        organization.github_client.org_hook(organization.github_id, organization.webhook_id)
      rescue Octokit::NotFound
        webhook = organization.github_organization.create_organization_webhook(config: { url: Organization::Creator.webhook_url })
        result = organization.update(webhook_id: webhook.id) if webhook.try(:id).present?
        organizations_touched += 1
      end
    end
  end
  puts "Organizations re-registered: #{organizations_touched}"
end
