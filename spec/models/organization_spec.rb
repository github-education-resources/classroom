require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe '#all_assignments' do
    subject { create(:organization) }

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

  describe '#github_client' do
    let(:organization) { create(:organization) }

    it 'selects a users github_client at random' do
      expect(organization.github_client.class).to eql(Octokit::Client)
    end
  end
end
