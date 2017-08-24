# frozen_string_literal: true

require "rails_helper"

describe GitHubClassroom::Scopes do
  subject { described_class }

  it "has the correct scopes for a teacher" do
    expect(subject::TEACHER)
      .to eql(%w[user:email repo delete_repo admin:org admin:org_hook])
  end

  it "has the correct scopes for a student accepting a group assignment" do
    expect(subject::GROUP_ASSIGNMENT_STUDENT).to eql(%w[admin:org user:email repo:invite])
  end

  it "has the correct scopes for a student accepting an individual assignment" do
    expect(subject::ASSIGNMENT_STUDENT).to eql(%w[user:email repo:invite])
  end

  it "ensures that the scopes are correctly sized" do
    expect(subject::TEACHER.size).to be > subject::GROUP_ASSIGNMENT_STUDENT.size
    expect(subject::GROUP_ASSIGNMENT_STUDENT.size).to be > subject::ASSIGNMENT_STUDENT.size
  end
end
