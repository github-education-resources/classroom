require 'rails_helper'

RSpec.describe Organization, type: :model do
  subject { create(:organization) }

  describe 'when title is changed' do
    it 'updates the slug' do
      subject.update_attributes(title: 'New Title')
      expect(subject.slug).to eql("#{subject.github_id}-new-title")
    end
  end

  describe '#access_token' do
    it 'selects a users access_token at random' do
      expect(subject.access_token).to eql(subject.users.first.access_token)
    end
  end

  describe '#all_assignments' do
    context 'new Organization' do
      it 'returns an empty array' do
        expect(subject.all_assignments).to be_kind_of(Array)
        expect(subject.all_assignments.count).to eql(0)
      end
    end

    context 'with Assignments and GroupAssignments' do
      let(:creator) { subject.users.first }

      before do
        grouping = Grouping.new(title: 'Grouping', organization: subject)

        Assignment.create(creator: creator, title: 'Assignment', organization: subject)
        GroupAssignment.create(creator: creator,
                               grouping: grouping,
                               organization: subject,
                               title: 'Group Assignment')
      end

      it 'should return an array of Assignments and GroupAssignments' do
        expect(subject.all_assignments).to be_kind_of(Array)
        expect(subject.all_assignments.count).to eql(2)
      end
    end
  end

  describe '#geo_pattern_data_uri' do
    it 'returns the proper geo pattern' do
      geo_pattern_data_uri = GeoPattern.generate(subject.github_id, color: '#5fb27b').to_data_uri
      expect(subject.geo_pattern_data_uri).to eql(geo_pattern_data_uri)
    end
  end

  describe '#github_organization' do
    it 'should return a GitHubOrganization' do
      expect(subject.github_organization).to be_instance_of(GitHubOrganization)
    end
  end

  describe '#flipper_id' do
    it 'should return an id' do
      expect(subject.flipper_id).to eq("Organization:#{subject.id}")
    end
  end
end
