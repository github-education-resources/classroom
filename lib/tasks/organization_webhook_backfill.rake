# frozen_string_literal: true

task organization_webhook_backfill: :environment do
  puts "Backfilling Organizations to belong to a OrganizationWebhook."

  # Record number of organizations updated
  organizations_updated = 0

  puts "Updating Organizations..."

  Organizations.where(organization_webhook_id: nil).find_in_batches(batch_size: 250) do |organizations|
    organizations_updated += organizations.length
    organizations.each do |organization|
      organization_webhook = OrganizationWebhook.find_or_initialize_by(github_organization_id: organization.github_id)
      organization_webhook.github_id ||= organization.webhook_id
      organization_webhook.save!
      organization.update!(organization_webhook_id: organization_webhook.id)
    end
  end

  puts "Done! We backfilled Organizations to belong to a OrganizationWebhook."
  puts "=> #{organizations_updated} Organizations were updated"
end
