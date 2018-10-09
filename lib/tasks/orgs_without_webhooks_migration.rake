# frozen_string_literal: true

task orgs_without_webhooks_stats: :environment do
  organizations_without_webhooks = []
  total_organizations_without_webhooks = 0
  Organization.find_in_batches(batch_size: 500) do |organizations_batch|
    organizations_batch.each do |organization|
      begin
        organization.github_client.org_hook(organization.github_id, organization.webhook_id)
      rescue Octokit::NotFound
        organizations_without_webhooks << organization.github_id
        total_organizations_without_webhooks += 1
      end
    end
  end
  puts "Total number of organizations without webhooks: #{total_organizations_without_webhooks}"
  puts "Org github_ids of orgs without webhooks:"
  pp organizations_without_webhooks
end
