# frozen_string_literal: true
module OrganizationWebhook
  extend ActiveSupport::Concern

  def create_organization_webhook
    unless explicit_assignment_submission_enabled?
      return yield if block_given?
    end

    @organization.create_organization_webhook(events_organization_url(@organization), current_user.github_client)
    yield if block_given?
  rescue => err
    @organization.destroy
    raise err
  end
end
