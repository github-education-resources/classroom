# frozen_string_literal: true
require 'rails_helper'

describe GitHub::Token do
  subject { described_class }

  let(:student) { classroom_student }

  describe '#scopes', :vcr do
    it 'returns the scopes of the token in an array' do
      expect(described_class.scopes(student.token)).to be_kind_of(Array)
    end
  end
end
