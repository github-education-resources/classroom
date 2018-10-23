# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec", "models", "concerns", "github_teamable_spec.rb")

RSpec.describe Group, type: :model do
  let(:organization) { classroom_org }
  let(:grouping)     { create(:grouping, organization: organization) }
  let(:user)         { classroom_student }

  it_behaves_like "github_teamable"

  describe "assocations", :vcr do
    before(:each) do
      @group = create(:group, grouping: grouping, title: "Toon Town")
      @group.create_github_team
      @group.save!
    end

    after(:each) do
      @group.try(:destroy)
      RepoAccess.destroy_all
    end

    it "has users" do
      repo_access = RepoAccess.create(user: user, organization: organization)
      @group.repo_accesses << repo_access
      expect(@group.users).to eq([user])
    end
  end

  describe "callbacks", :vcr do
    before(:each) do
      @group = create(:group, grouping: grouping, title: "Toon Town")
      @group.create_github_team
      @group.save!
    end

    after(:each) do
      @group.try(:destroy)
    end

    describe "assocation callbacks" do
      before(:each) do
        @repo_access = RepoAccess.create(user: user, organization: organization)
        @group.repo_accesses << @repo_access
      end

      after(:each) do
        RepoAccess.destroy_all
      end

      describe "before_add" do
        describe "#add_member_to_github_team" do
          it "adds the user to the GitHub team" do
            github_user     = GitHubUser.new(@repo_access.user.github_client, @repo_access.user.uid)
            memberships_url = "teams/#{@group.github_team_id}/memberships/#{github_user.login}"

            expect(WebMock).to have_requested(:put, github_url(memberships_url))
          end
        end
      end

      describe "before_destroy" do
        describe "#remove_from_github_team" do
          it "removes the user from the GitHub team" do
            github_user = GitHubUser.new(@repo_access.user.github_client, @repo_access.user.github_client)

            @group.repo_accesses.delete(@repo_access)
            rmv_from_team_github_url = github_url("/teams/#{@group.github_team_id}/memberships/#{github_user.login}")
            expect(WebMock).to have_requested(:delete, rmv_from_team_github_url)
          end
        end
      end
    end
  end

  describe "group_invite_statuses", :vcr do
    let(:organization) { classroom_org }
    let(:grouping)     { create(:grouping, organization: organization) }
    let(:group)        { create(:group, grouping: grouping, title: "#{Faker::Company.name} Team") }
    let(:invitation1)  { create(:group_assignment_invitation) }
    let(:invitation2)  { create(:group_assignment_invitation) }

    it "returns a list of invite statuses" do
      group_invite_status = GroupInviteStatus.create(group: group, group_assignment_invitation: invitation1)
      expect(group.group_invite_statuses).to eq([group_invite_status])
    end

    context "on #destroy" do
      before do
        expect(group)
          .to receive(:silently_destroy_github_team)
          .and_return(true)
      end

      it "on #destroy destroys invite status and not the invitation" do
        group_invite_status = GroupInviteStatus.create(group: group, group_assignment_invitation: invitation1)
        group.destroy
        expect { group_invite_status.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(invitation1.reload.nil?).to be_falsey
      end

      it "on #destroy destroys all invite statuses" do
        group_invite_status1 = GroupInviteStatus.create(group: group, group_assignment_invitation: invitation1)
        group_invite_status2 = GroupInviteStatus.create(group: group, group_assignment_invitation: invitation2)
        group.destroy
        expect { group_invite_status1.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { group_invite_status2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

  end
end
