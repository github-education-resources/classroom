# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RepoAccess, type: :model do
  describe 'callbacks', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org }
    let(:student)      { GitHubFactory.create_classroom_student   }

    before(:each) do
      @repo_access = RepoAccess.create(user: student, organization: organization)
    end

    after(:each) do
      @repo_access.destroy if @repo_access.present?
    end

    describe 'before_validation' do
      describe '#add_membership_to_github_organization' do
        it 'adds the users membership to the GitHub organization' do
          student_github_login = GitHubUser.new(student.github_client, student.uid).login
          add_membership_github_url = github_url("/orgs/#{organization.title}/memberships/#{student_github_login}")

          expect(WebMock).to have_requested(:put, add_membership_github_url)
        end
      end

      describe '#accept_membership_to_github_organization' do
        it 'accepts the users membership to the Organization' do
          expect(WebMock).to have_requested(:patch, github_url("/user/memberships/orgs/#{organization.title}"))
            .with(headers: { 'Authorization' => "token #{student.token}" })
        end
      end
    end

    describe 'before_destroy' do
      describe '#silently_remove_organization_member' do
        context 'user is a member of the organization' do
          it 'removes the user' do
            @repo_access.destroy

            student_github_login = GitHubUser.new(student.github_client, student.uid).login
            delete_request_url   = "/organizations/#{organization.github_id}/members/#{student_github_login}"
            expect(WebMock).to have_requested(:delete, github_url(delete_request_url))
          end
        end

        context 'user is an owner of the organization' do
          it 'does not remove the user' do
            owner_repo_access = RepoAccess.create(user: organization.users.first, organization: organization)
            owner_repo_access.destroy

            student_github_login = GitHubUser.new(student.github_client, student.uid).login
            delete_request_url   = "/organizations/#{organization.github_id}/members/#{student_github_login}"
            expect(WebMock).to_not have_requested(:delete, github_url(delete_request_url))
          end
        end
      end
    end
  end
end
