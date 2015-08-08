require 'rails_helper'

RSpec.describe Organization, type: :model do
  it { is_expected.to have_many(:assignments).dependent(:destroy)       }
  it { is_expected.to have_many(:groupings).dependent(:destroy)         }
  it { is_expected.to have_many(:group_assignments).dependent(:destroy) }
  it { is_expected.to have_many(:repo_accesses).dependent(:destroy)     }

  it { is_expected.to have_and_belong_to_many(:users) }

  it_behaves_like 'a default scope where deleted_at is not present'

  describe 'validation and uniqueness' do
    subject { create(:organization) }

    it { is_expected.to validate_presence_of(:github_id)   }
    it { is_expected.to validate_uniqueness_of(:github_id) }

    it { is_expected.to validate_presence_of(:title)                    }
    it { is_expected.to validate_uniqueness_of(:title).case_insensitive }
  end

  describe 'callbacks' do
    describe 'assocation callbacks' do
      describe 'before_remove' do
        describe '#verify_not_last_user' do
          subject { create(:organization) }

          it 'verifies that the last users is not being removed' do
            begin
              subject.users.destroy_all
            rescue => e
              expect(e.message).to eql('unable to remove user')
              expect(subject.errors.count).to eql(1)
              expect(subject.users.count).to eql(1)
              expect(subject.errors.full_messages.first).to eql('This organization must have at least one active user')
            end
          end
        end

        describe '#verify_not_assignment_creator' do
          subject          { create(:organization)                                                                }
          let(:assignment) { Assignment.create(title: 'Ruby', creator: subject.users.last, organization: subject) }

          it 'verifies that the user being removed is not the creator of an assignment' do
            begin
              assignment # For some reason the object isn't actually created until called
              error_message = 'User is the creator of one or more assignments, and cannot be removed at this time'
              subject.users.destroy_all
            rescue => e
              expect(e.message).to eql('unable to remove user')
              expect(subject.errors.count).to eql(1)
              expect(subject.users.count).to eql(1)
              expect(subject.errors.full_messages.first).to eql(error_message)
            end
          end
        end
      end
    end
  end

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
