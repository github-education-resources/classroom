# frozen_string_literal: true
class PingOrganizationWebhookJob < ApplicationJob
  queue_as :github_webhooks

  rescue_from(GitHub::Error) do
    retry_job wait: 1.minute, queue: :github_webhook_failures
  end

  def perform(organization_id, user_id)
    organization = Organization.includes(:users).find(organization_id)
    user = organization.users.find(user_id)
    if organization.webhook_id.present? && !organization.is_webhook_active?
      organization.ping_organization_webhook(user.github_client)
    end
  rescue ActiveRecord::RecordNotFound
    return
  end
end
