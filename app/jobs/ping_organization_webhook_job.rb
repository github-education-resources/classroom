# frozen_string_literal: true
class PingOrganizationWebhookJob < ApplicationJob
  queue_as :github_webhook

  def should_perform_job?(organization, user)
    (organization.present? && user.present?) &&
      (organization.webhook_id.present? && !organization.is_webhook_active?)
  end

  def perform(organization_id, user_id)
    organization = Organization.find_by(id: organization_id)
    user = User.find_by(id: user_id)

    return unless should_perform_job?(organization, user)

    organization.ping_organization_webhook(user.github_client)
  ensure
    if should_perform_job?(organization, user)
      self.class.set(wait: 1.minute).perform_later(organization_id, user_id)
    end
  end
end
