# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AssignmentRepo::Creator, type: :model do
  let(:organization) { GitHubFactory.create_owner_classroom_org }
  let(:student)      { GitHubFactory.create_classroom_student }

  let(:assignment) do
    options = {
      title: 'Learn Elm',
      starter_code_repo_id: 1_062_897,
      organization: organization,
      students_are_repo_admins: true
    }

    create(:assignment, options)
  end

  after(:each) do
    AssignmentRepo.destroy_all
  end

  describe '::perform', :vcr do
    describe 'successful creation' do
      it 'creates an AssignmentRepo' do
        result = AssignmentRepo::Creator.perform(assignment: assignment, invitee: student)

        expect(result.success?).to be_truthy
        expect(result.assignment_repo.assignment).to eql(assignment)
        expect(result.assignment_repo.user).to eql(student)
      end
    end
  end
end
