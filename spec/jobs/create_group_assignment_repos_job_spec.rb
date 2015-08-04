require 'rails_helper'

RSpec.describe CreateGroupAssignmentReposJob, type: :job do
  let(:organization) { GitHubFactory.create_owner_classroom_org }

  let(:repo_access) do
    student = GitHubFactory.create_classroom_student
    RepoAccess.create(user: student, organization: organization)
  end

  let(:group_assignment) { create(:group_assignment, organization: organization, starter_code_repo_id: 40_140_589) }

  after(:each) do
    RepoAccess.destroy_all
    Group.destroy_all
    GroupAssignmentRepo.destroy_all
  end

  context 'a GroupAssignment with a new Grouping' do
    it 'does not create any GroupAssignmentRepos' do
      assert_performed_with(job: CreateGroupAssignmentReposJob, args: [group_assignment.id]) do
        CreateGroupAssignmentReposJob.perform_later(group_assignment.id)
      end

      expect(GroupAssignmentRepo.all.count).to eql(0)
    end
  end

  context 'a GroupAssignment with an existing Grouping with Groups', :vcr do
    it 'creates a GroupAssignmentRepo for each group' do
      group = Group.create(grouping: group_assignment.grouping, title: 'Group 1')
      group.repo_accesses << repo_access

      assert_performed_with(job: CreateGroupAssignmentReposJob, args: [group_assignment.id]) do
        CreateGroupAssignmentReposJob.perform_later(group_assignment.id)
      end

      expect(GroupAssignmentRepo.all.count).to eql(1)
    end
  end
end
