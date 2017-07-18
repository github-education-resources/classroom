# frozen_string_literal: true

require "rails_helper"

RSpec.describe HooksController, type: :controller do
  before do
    set_http_header("HTTP_X_HUB_SIGNATURE", "sha1=#{GitHub::WebHook.generate_hmac('{"foo":"bar"}')}")
  end

  describe "invalid webhook request" do
    it "responds with a 400 if there is not payload" do
      send_webhook(nil)
      expect(response).to have_http_status(400)
    end

    it "responds with :forbidden if the signatures are not a match" do
      set_http_header("HTTP_X_HUB_SIGNATURE", "foo")
      send_webhook(foo: "bar")
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "valid webhook request" do
    it "responds :ok for a valid request" do
      send_webhook(foo: "bar")
      expect(response).to have_http_status(:ok)
    end

    GitHub::WebHook::ACCEPTED_EVENTS.map do |event|
      it "queues a job for the '#{event}' event" do
        set_http_header("HTTP_X_GITHUB_EVENT", event)
        job_class = "#{event}_event_job".classify.constantize

        expect do
          send_webhook(foo: "bar")
        end.to have_enqueued_job(job_class)
      end
    end
  end

  private

  def set_http_header(header, value)
    request.env[header] = value
  end

  def send_webhook(payload)
    post :receive, body: payload.to_json, as: :json
  end
end
