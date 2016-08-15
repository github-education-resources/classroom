# frozen_string_literal: true
class WebhookEventsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  before_action :verify_payload_signature
  before_action :verify_organization_presence
  before_action :verify_sender_presence

  def create
    if respond_to? event_handler
      send event_handler
      head :ok, content_type: 'application/json'
    else
      not_found
    end
  end

  def handle_ping
    return if @organization.is_webhook_active?
    @organization.update_attributes(is_webhook_active: true)
  end

  private

  def event_name
    request.headers['X-GitHub-Event']
  end

  def event_handler
    @event_handler ||= "handle_#{event_name}".to_sym
  end

  def verify_payload_signature
    return unless Rails.application.secrets.webhook_secret.present?

    algorithm, signature = request.headers['X-Hub-Signature'].split('=')
    payload_validated = actual_payload_signature(algorithm) == signature
    not_found unless payload_validated
  end

  def actual_payload_signature(algorithm)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new(algorithm),
                            Rails.application.secrets.webhook_secret,
                            request.body.read)
  end

  def verify_organization_presence
    payload_github_id = params.dig(:organization, :id).to_s
    path_github_id = params[:organization_id].split('-').first.to_s
    return not_found unless payload_github_id == path_github_id
    @organization ||= Organization.find_by(github_id: payload_github_id)
    not_found unless @organization.present?
  end

  def verify_sender_presence
    @sender ||= User.find_by(uid: params.dig(:sender, :id))
    not_found unless @sender.present?
  end
end
