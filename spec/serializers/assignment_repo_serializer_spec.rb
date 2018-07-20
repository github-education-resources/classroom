# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::AssignmentRepoSerializer, type: :serializer do
  let(:organization)      { classroom_org                                                                    }
  let(:user)              { classroom_teacher                                                                }
  let(:assignment)        { create(:assignment, organization: organization, title: "Learn Clojure")          }
  let(:assignment_repo)   { create(:assignment_repo, assignment: assignment, github_repo_id: 42, user: user) }

  describe "AssignmentRepoSerializer attributes check", :vcr do
    before(:each) do
      @assignment_repo_json = described_class.new(assignment_repo).as_json
    end

    it "returns repo username" do
      binding.pry
      expect(@assignment_repo_json[:username]).to eq(user.github_user.login)
    end

    it "returns repo url" do
      expect(@assignment_repo_json[:repoUrl]).to eq(assignment_repo.github_repository.html_url)
    end

    it "returns user display name" do
      expect(@assignment_repo_json[:displayName]).to eq(user.github_user.name)
    end
  end
end
