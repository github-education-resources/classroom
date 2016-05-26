# frozen_string_literal: true
require 'rails_helper'

describe Classroom::Scopes do
  subject { described_class }

  it 'has the correct scopes for a teacher' do
    expect(subject::TEACHER).to eql(%w(user:email repo delete_repo admin:org))
  end

  it 'has the correct scopes for a student accepting a group assignment' do
    expect(subject::GROUP_ASSIGNMENT_STUDENT).to eql(%w(admin:org user:email))
  end

  it 'has the correct scopes for a student accepting an individual assignment' do
    expect(subject::ASSIGNMENT_STUDENT).to eql(%w(user:email))
  end
end
