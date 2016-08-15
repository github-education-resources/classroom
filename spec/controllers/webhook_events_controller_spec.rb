# frozen_string_literal: true
require 'rails_helper'

RSpec.describe WebhookEventsController, type: :controller do
  include ActiveJob::TestHelper

  let(:organization)  { GitHubFactory.create_owner_classroom_org }
  let(:user)          { organization.users.first                 }

  describe 'POST #create' do
    describe 'ping event' do
      context 'valid payload signature' do
        before(:each) do
          payload = File.read("#{Rails.root}/spec/fixtures/webhook_events/ping.json").strip

          algorithm = 'sha1'
          signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new(algorithm),
                                              Rails.application.secrets.webhook_secret,
                                              payload)

          request.headers['X-Hub-Signature'] = "#{algorithm}=#{signature}"
          request.headers['X-GitHub-Event'] = 'ping'
          request.headers['CONTENT_TYPE'] = 'application/json'

          post :create, payload, JSON.parse(payload).merge(organization_id: organization.slug)
        end
        it 'returns success' do
          expect(response).to have_http_status(:success)
        end
      end
    end
  end
end
