require 'rails_helper'

RSpec.describe AssignmentRepo, type: :model do
  it { is_expected.to belong_to(:assignment)  }
  it { is_expected.to belong_to(:repo_access) }

  describe 'validation and uniqueness' do
    subject { AssignmentRepo.new }
    it { is_expected.to validate_presence_of(:assignment) }

    it { is_expected.to validate_presence_of(:github_repo_id) }
    # it { is_expected.to validate_uniqueness_of(:github_repo_id) }

    it { is_expected.to validate_presence_of(:repo_access) }
  end

  context 'with created objects', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org                                      }
    let(:repo_access)  { RepoAccess.create(user: organization.users.first, organization: organization) }

    let(:assignment) do
      Assignment.create(creator: repo_access.user, title: 'Learn Ruby', organization: organization, public_repo: false)
    end

    before(:each) do
      @assignment_repo = AssignmentRepo.create(assignment: assignment, repo_access: repo_access)
    end

    after(:each) do
      @assignment_repo.destroy if @assignment_repo
    end

    after do
      repo_access.destroy
    end

    describe 'callbacks' do
      describe 'before_validation' do
        describe '#create_github_repository' do
          it 'creates the repository on GitHub' do
            assert_requested :post, github_url("/organizations/#{organization.github_id}/repos")
          end
        end
      end

      describe 'before_create' do
        describe '#add_team_to_github_repository' do
          it 'adds the team to the repository' do
            github_repo = GitHubRepository.new(organization.github_client, @assignment_repo.github_repo_id)
            assert_requested :put, github_url("/teams/#{repo_access.github_team_id}/repos/#{github_repo.full_name}")
          end
        end
      end

      describe 'before_destroy' do
        describe '#destroy_github_repository' do
          it 'deletes the repository from GitHub' do
            repo_id = @assignment_repo.github_repo_id
            @assignment_repo.destroy

            assert_requested :delete, github_url("/repositories/#{repo_id}")
          end
        end
      end
    end

    describe '#creator' do
      it 'returns the assignments creator' do
        expect(@assignment_repo.creator).to eql(assignment.creator)
      end
    end
  end
end
