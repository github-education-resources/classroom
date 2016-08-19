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
          params = JSON.parse(File.open("#{Rails.root}/spec/support/fixtures/webhook_payloads/ping.json").read)
          params.symbolize_keys!
          params[:sender][:id] = user.uid
          params[:organization][:id] = organization.github_id

          payload = params.to_json

          if Rails.application.secrets.webhook_secret.present?
            signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'),
                                                Rails.application.secrets.webhook_secret,
                                                payload)

            request.headers['X-Hub-Signature'] = "sha1=#{signature}"
          end

          request.headers['X-GitHub-Event'] = 'ping'

          post :create, payload, params.merge(organization_id: organization.slug)
        end

        it 'returns success' do
          expect(response).to have_http_status(:success)
        end

        it 'updates organization is_webhook_active value' do
          organization.reload
          expect(organization.is_webhook_active).to be_truthy
        end
      end
    end
  end
end
