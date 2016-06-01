# frozen_string_literal: true
class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token, :authenticate_user!,
                     :set_organization, :authorize_organization_access

  before_action :verify_organization_presence
  before_action :verify_payload_signature

  def events
    case request.headers['X-GitHub-Event']
    when 'ping'
      update_org_hook_status
    else
      render nothing: true, status: 200
    end
  end

  private

  def organization
    org_id = params.dig(:organization, :id)
    return nil unless org_id.present?
    @organization ||= Organization.find_by(github_id: org_id)
  end

  def update_org_hook_status
    unless organization.is_webhook_active?
      organization.update_attributes(is_webhook_active: true)
    end
    render nothing: true, status: 200
  end

  def verify_organization_presence
    not_found unless organization.present?
  end

  def verify_payload_signature
    algorithm, signature = request.headers['X-Hub-Signature'].split('=')

    payload_validated = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new(algorithm),
                                                ENV['WEBHOOK_SECRET'],
                                                request.body.read) == signature
    not_found unless payload_validated
  end
end
