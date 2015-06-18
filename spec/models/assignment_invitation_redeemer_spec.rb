require 'rails_helper'

RSpec.describe AssignmentInvitationRedeemer, type: :model do
  let(:invitation_redeemer) { build(:assignment_invitation_redeemer)               }
  let(:organization)        { invitation_redeemer.organization                     }
  let(:invitation)          { invitation_redeemer.assignment.assignment_invitation }

  before do
    @stub_values = {
      team_id:        12,
      team_name:      'Team: 1',
      user_login:     'user',
      repo_id:        8_675_309,
      repo_name:      "#{invitation.assignment.title}: 1",
      full_repo_name: "user/#{invitation.assignment.title.parameterize}-1"
    }
  end

  before(:each) do
    @request_stubs = []
  end

  after(:each) do
    @request_stubs.each do |request_stub|
      expect(request_stub).to have_been_requested.once
    end
  end

  describe '#redeemed?' do
    it 'will return true if the RepoAccess and AssignmentRepo are correctly created or found' do
      @request_stubs << stub_github_organization(organization.github_id,
                                                 login: organization.title,
                                                 id: organization.github_id)

      @request_stubs << stub_create_github_team(organization.github_id,
                                                { name: @stub_values[:team_name], permission: 'push' },
                                                id: @stub_values[:team_id])

      @request_stubs << stub_github_user(nil, login: @stub_values[:user_login])

      @request_stubs << stub_add_team_membership(@stub_values[:team_id], @stub_values[:user_login], state: 'pending')

      repo_options = {
        has_issues:    true,
        has_wiki:      true,
        has_downloads: true,
        team_id:       @stub_values[:team_id],
        private:       false,
        name:          @stub_values[:repo_name]
      }

      @request_stubs << stub_create_github_organization_repo(organization.title,
                                                             repo_options,
                                                             id: @stub_values[:repo_id],
                                                             name: @stub_values[:repo_name])

      @request_stubs << stub_github_repo(@stub_values[:repo_id], full_name: @stub_values[:full_repo_name])
      @request_stubs << stub_github_team_repository?(@stub_values[:team_id], @stub_values[:full_repo_name], 204, nil)

      result = invitation_redeemer.redeemed?
      expect(result).to eq(true)
    end
  end
end
