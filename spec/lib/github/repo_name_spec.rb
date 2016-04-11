require 'rails_helper'

describe GitHub::RepoName do
  let(:user)    { GitHubFactory.create_owner_classroom_org.users.first }
  let(:student) { GitHubFactory.create_classroom_student               }

  let(:organization) { user.organizations.first }

  let(:assignment) { Assignment.create(title: 'HTML5', creator: user, organization: organization, public_repo: false) }

  describe '#generate_github_repository_name', :vcr do
    context 'github repository with the same name does not exist' do
      it 'has correct repository name' do
        repo_name = described_class.new(organization.github_client,
                                        organization.decorate.login,
                                        student.decorate.login,
                                        assignment.slug).repo_name
        expect(repo_name).to eql("#{assignment.slug}-#{student.decorate.login}")
      end
    end

    context 'github repository with the same name already exists' do
      let(:assignment_repo) { AssignmentRepo.new(assignment: assignment, user: student) }

      before do
        assignment_repo.create_github_repository
      end

      it 'has correct repository name' do
        repo_name = described_class.new(organization.github_client,
                                        organization.decorate.login,
                                        student.decorate.login,
                                        assignment.slug).repo_name
        expect(repo_name).to eql("#{assignment.slug}-#{student.decorate.login}-1")
      end

      after do
        assignment_repo.destroy_github_repository
      end
    end

    context 'github repository name is too long' do
      let(:repo_name_client) do
        GitHub::RepoName.new(organization.github_client, organization.decorate.login, 'u' * 39, 'a' * 60)
      end

      before(:each) do
        repo_name_client.instance_variable_set(:@suffix_number, 20)
      end

      it 'truncates the repository name into 100 characters' do
        expect(repo_name_client.repo_name.length).to eql(100)
      end

      it 'does not remove the repository name suffix' do
        expect(repo_name_client.repo_name).to end_with('-20')
      end
    end
  end
end
