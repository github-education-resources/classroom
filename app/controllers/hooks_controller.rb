# frozen_string_literal: true

class HooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  before_action :verify_payload

  def receive
    send_github_payload_to_job(payload_hash)
    update_last_webhook_recieved(payload_hash)
    head :ok
  end

  private

  def payload_body
    @payload_body ||= request.body.read
  end

  def payload_hash
    @payload_hash ||= JSON.parse(payload_body)
  end

  def send_github_payload_to_job(payload_hash)
    github_event = request.env["HTTP_X_GITHUB_EVENT"]
    return unless GitHub::WebHook::ACCEPTED_EVENTS.include?(github_event)
    "#{github_event}_event_job".classify.constantize.perform_later(payload_hash)
  end

  def verify_payload
    return render json: { message: "No payload received" }, status: 400 if payload_body == "null"

    expected_signature = "sha1=#{GitHub::WebHook.generate_hmac(payload_body)}"
    received_signature = request.env["HTTP_X_HUB_SIGNATURE"]

    # rubocop:disable GuardClause
    unless received_signature && Rack::Utils.secure_compare(received_signature, expected_signature)
      return render json: { message: "Invalid payload signature" }, status: :forbidden
    end
    # rubocop:enable GuardClause
  end

  def update_last_webhook_recieved(payload_hash)
    github_organization_id = payload_hash.dig("organization", "id")
    return false unless github_organization_id
    OrganizationWebhook
      .find_by!(github_organization_id: github_organization_id)
      .update_columns(last_webhook_recieved: Time.now.utc) # rubocop:disable Rails/SkipsModelValidations
    true
  end
end
