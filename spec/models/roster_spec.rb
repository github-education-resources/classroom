# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Roster, type: :model do
  subject { create(:roster) }

  describe 'associations' do
    it 'can have roster_entries' do
      subject.roster_entries << create(:roster_entry)

      expect(subject.valid?).to be_truthy
    end

    it 'can have organizations' do
      subject.organizations << create(:organization)

      expect(subject.valid?).to be_truthy
    end
  end
end
