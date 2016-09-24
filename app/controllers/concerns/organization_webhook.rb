# frozen_string_literal: true
module OrganizationWebhook
  extend ActiveSupport::Concern

  def create_organization_webhook
    unless explicit_assignment_submission_enabled?
      return yield if block_given?
    end

    @organization.create_organization_webhook(organization_webhook_events_url(@organization),
                                              current_user.github_client)
    schedule_ping_org_hook_job(@organization, current_user)
    yield if block_given?
  rescue => err
    @organization.destroy
    raise err
  end

  def schedule_ping_org_hook_job(organization, user)
    PingOrganizationWebhookJob.set(wait: 1.minute).perform_later(organization.id, user.id)
  end
end
