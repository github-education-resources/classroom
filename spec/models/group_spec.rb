require 'rails_helper'

RSpec.describe Group, type: :model do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:grouping)     { Grouping.create(title: 'Grouping 1', organization: organization) }

  it { is_expected.to have_one(:organization).through(:grouping) }

  it { is_expected.to belong_to(:grouping) }

  it { is_expected.to have_and_belong_to_many(:repo_accesses) }

  describe 'validation and uniqueness', :vcr do
    subject { Group.new(title: 'Group 1', grouping: grouping) }

    # it { is_expected.to validate_presence_of(:github_team_id) }
    it { is_expected.to validate_presence_of(:grouping)       }
    # it { is_expected.to validate_presence_of(:title)          }
    #
    it { is_expected.to validate_uniqueness_of(:github_team_id) }
  end

  describe 'callbacks', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org }
    let(:grouping)     { Grouping.create(title: 'Grouping 1', organization: organization) }

    before(:each) do
      @group = Group.create(grouping: grouping, title: 'Toon Town')
    end

    after(:each) do
      @group.destroy if @group
    end

    describe 'before_validation' do
      describe '#create_github_team' do
        it 'creates the team on GitHub' do
          assert_requested :post, github_url("/organizations/#{organization.github_id}/teams")
        end
      end
    end

    describe 'assocation callbacks' do
      let(:user) { GitHubFactory.create_classroom_student }

      before(:each) do
        @repo_access = RepoAccess.create(user: user, organization: organization)
        @group.repo_accesses << @repo_access
      end

      after(:each) do
        @repo_access.destroy if @repo_access
      end

      describe 'before_add' do
        describe '#add_member_to_github_team' do
          it 'adds the user to the GitHub team' do
            memberships_url = "teams/#{@group.github_team_id}/memberships/#{@repo_access.user.github_login}"

            assert_requested :put, github_url(memberships_url)
            assert_requested :patch, github_url("/user/memberships/orgs/#{organization.title}")
          end
        end
      end

      describe 'before_destroy' do
        describe '#remove_from_github_team' do
          it 'removes the user from the GitHub team'do
            user_login = @repo_access.user.github_login

            @group.repo_accesses.delete(@repo_access)
            assert_requested :delete, github_url("/teams/#{@group.github_team_id}/memberships/#{user_login}")
          end
        end
      end
    end
  end
end
