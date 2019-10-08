# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignmentRepo, type: :model do
  let(:organization) { classroom_org     }
  let(:student)      { classroom_student }
  let(:assignment)   { create(:assignment, organization: organization) }

  subject { create(:assignment_repo, assignment: assignment, github_repo_id: 42) }

  describe ".search" do
    it "searches by id" do
      results = AssignmentRepo.search(subject.id)
      expect(results.to_a).to include(subject)
    end

    it "searches by github_repo_id" do
      results = AssignmentRepo.search(subject.github_repo_id)
      expect(results.to_a).to include(subject)
    end

    it "does not return the assignment when it shouldn't" do
      results = AssignmentRepo.search("spaghetto")
      expect(results.to_a).to_not include(subject)
    end
  end

  describe "callbacks", :vcr do
    describe "before_destroy" do
      describe "#silently_destroy_github_repository" do
        it "deletes the repository from GitHub" do
          subject.destroy
          expect(WebMock).to have_requested(:delete, github_url("/repositories/#{subject.github_repo_id}"))
        end
      end
    end
  end

  describe "#creator" do
    it "returns the assignments creator" do
      expect(subject.creator).to eql(assignment.creator)
    end
  end

  describe "#user" do
    it "returns the user" do
      expect(subject.user).to be_a(User)
    end

    context "assignment_repo has a user through a repo_access", :vcr do
      let(:repo_access) { RepoAccess.create(user: student, organization: organization) }

      subject { create(:assignment_repo, repo_access: repo_access, user: nil) }

      after(:each) do
        RepoAccess.destroy_all
      end

      it "returns the user" do
        expect(subject.user).to eql(student)
      end
    end
  end

  describe "belongs_to repo_access" do
    it "is optional" do
      repo = build(:assignment_repo, assignment: assignment, github_repo_id: 42)
      repo.repo_access = nil

      expect(repo.valid?).to be_truthy
    end

    it "expects github_team_id to be nil" do
      repo = build(:assignment_repo, assignment: assignment, github_repo_id: 42)
      repo.repo_access = nil

      expect(repo.github_team_id).to be_nil
    end
  end

  describe "#assignment_user_key_uniqueness" do
    context "valid" do
      it "passes validation" do
        expect(subject.valid?).to be_truthy
      end
    end

    context "invalid" do
      it "fails validation" do
        assignment_repo = subject
        expect { create(:assignment_repo, assignment: assignment_repo.assignment, user: assignment_repo.user) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "invalid but already exists" do
      it "passes validation" do
        assignment_repo = subject
        non_unique_assignment_repo = build(
          :assignment_repo,
          assignment: assignment_repo.assignment,
          user: assignment_repo.user
        )
        non_unique_assignment_repo.save!(validate: false)
        expect(non_unique_assignment_repo.valid?).to be_truthy
      end
    end
  end

  describe "is sortable", :vcr do
    let(:assignment_repo_one) { create(:assignment_repo, assignment: assignment) }
    let(:assignment_repo_two) { create(:assignment_repo, assignment: assignment) }

    # TODO: we don't have cached github attributes on the user factory
    # but adding them messes up a ... lot ... of casettes.
    before(:each) do
      assignment_repo_one.user.github_login = "ONE"
      assignment_repo_two.user.github_login = "TWO"

      assignment_repo_one.user.save!
      assignment_repo_two.user.save!
    end

    after(:each) do
    end

    it "order_by_sort_mode sorts by 'Team name'" do
      expected_ordering = [assignment_repo_one, assignment_repo_two].sort_by { |repo| repo.user.github_login }
      actual_ordering = AssignmentRepo.where(assignment: assignment).order_by_sort_mode("GitHub login")

      expect(actual_ordering).to eq(expected_ordering)
    end

    it "order_by_sort_mode sorts by 'Created at'" do
      expected_ordering = [assignment_repo_one, assignment_repo_two].sort_by(&:created_at)
      actual_ordering = AssignmentRepo.where(assignment: assignment).order_by_sort_mode("Created at")

      expect(actual_ordering).to eq(expected_ordering)
    end
  end

  describe "is searchable", :vcr do
    let(:assignment_repo_one) { create(:assignment_repo, assignment: assignment) }
    let(:assignment_repo_two) { create(:assignment_repo, assignment: assignment) }

    before(:each) do
      assignment_repo_one.user.github_login = "ONE"
      assignment_repo_two.user.github_login = "TWO"

      assignment_repo_one.user.save!
      assignment_repo_two.user.save!
    end

    it "filter_by_search searches by 'GitHub login'" do
      query = assignment_repo_one.user.github_login

      expected = [assignment_repo_one, assignment_repo_two].select { |r| r.user.github_login == query }
      actual = AssignmentRepo.where(assignment: assignment).filter_by_search(query)

      expect(actual).to eq(expected)
    end
  end
end
