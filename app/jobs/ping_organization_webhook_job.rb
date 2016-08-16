# frozen_string_literal: true
class PingOrganizationWebhookJob < ApplicationJob
  queue_as :github_webhook

  def perform(organization, user)
    return if organization.is_webhook_active?

    organization.ping_org_hook(user.github_client)
  ensure
    self.class.set(wait: 1.minute).perform_later(organization, user) unless organization.is_webhook_active?
  end
end
