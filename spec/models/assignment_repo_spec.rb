# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AssignmentRepo, type: :model do
  let(:organization) { GitHubFactory.create_owner_classroom_org  }
  let(:student)      { GitHubFactory.create_classroom_student    }
  let(:assignment)   { create(:assignment, organization: organization, creator: organization.users.first) }

  subject { create(:assignment_repo, assignment: assignment, github_repo_id: 42) }

  describe 'callbacks', :vcr do
    describe 'before_destroy' do
      describe '#silently_destroy_github_repository' do
        it 'deletes the repository from GitHub' do
          subject.destroy
          expect(WebMock).to have_requested(:delete, github_url("/repositories/#{subject.github_repo_id}"))
        end
      end
    end
  end

  describe '#creator' do
    it 'returns the assignments creator' do
      expect(subject.creator).to eql(assignment.creator)
    end
  end

  describe '#user' do
    it 'returns the user' do
      expect(subject.user).to be_a(User)
    end

    context 'assignment_repo has a user through a repo_access', :vcr do
      before do
        @repo_access = RepoAccess.create(user: student, organization: organization)
      end

      after do
        RepoAccess.destroy_all
      end

      subject { create(:assignment_repo, repo_access: @repo_access, user: nil) }

      it 'returns the user' do
        expect(subject.user).to eql(student)
      end
    end
  end
end
