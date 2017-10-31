# frozen_string_literal: true

class HooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  before_action :verify_payload

  def receive
    send_github_payload_to_job(JSON.parse(payload_body))
    head :ok
  end

  private

  def payload_body
    @payload_body ||= request.body.read
  end

  def send_github_payload_to_job(payload_body)
    github_event = request.env["HTTP_X_GITHUB_EVENT"]
    return unless GitHub::WebHook::ACCEPTED_EVENTS.include?(github_event)
    "#{github_event}_event_job".classify.constantize.perform_later(payload_body)
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
end
