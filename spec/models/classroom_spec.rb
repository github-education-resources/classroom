# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Classroom, type: :model do
  subject { create(:classroom) }

  describe 'when title is changed' do
    it 'updates the slug' do
      subject.update_attributes(title: 'New Title')
      expect(subject.slug).to eql("#{subject.github_id}-new-title")
    end
  end

  describe '#all_assignments' do
    context 'new Classroom' do
      it 'returns an empty array' do
        expect(subject.all_assignments).to be_kind_of(Array)
        expect(subject.all_assignments.count).to eql(0)
      end
    end

    context 'with Assignments and GroupAssignments' do
      let(:creator) { subject.users.first }

      before do
        grouping = Grouping.new(title: 'Grouping', classroom: subject)

        Assignment.create(creator: creator, title: 'Assignment', slug: 'assignment', classroom: subject)
        GroupAssignment.create(creator: creator,
                               grouping: grouping,
                               organization: subject,
                               slug: 'group-assignment',
                               title: 'Group Assignment')
      end

      it 'should return an array of Assignments and GroupAssignments' do
        expect(subject.all_assignments).to be_kind_of(Array)
        expect(subject.all_assignments.count).to eql(2)
      end
    end
  end

  describe '#flipper_id' do
    it 'should return an id' do
      expect(subject.flipper_id).to eq("Classroom:#{subject.id}")
    end
  end

  describe '#github_client' do
    it 'selects a users github_client at random' do
      expect(subject.github_client.class).to eql(Octokit::Client)
    end
  end

  context 'with valid classroom', :vcr do
    let(:subject) { GitHubFactory.create_owner_classroom_org }

    after(:each) do
      subject.destroy
    end

    describe '#create_classroom_webhook' do
      it 'sets webhook_id' do
        expect { subject.create_organization_webhook('http://localhost') }.to change { subject.webhook_id }
      end

      it 'creates a webhook on GitHub' do
        org_id = subject.github_organization_id
        subject.create_organization_webhook('http://localhost')
        expect(WebMock).to have_requested(:post, github_url("/organizations/#{org_id}/hooks"))
      end
    end

    describe 'callbacks' do
      describe 'before_destroy' do
        describe '#silently_remove_organization_webhook' do
          before do
            subject.create_organization_webhook('http://localhost')
          end

          it 'deletes the webhook from GitHub' do
            org_id = subject.github_organization_id
            webhook_id = subject.webhook_id
            subject.destroy

            expect(WebMock).to have_requested(:delete, github_url("/organizations/#{org_id}/hooks/#{webhook_id}"))
          end
        end
      end
    end
  end
end
