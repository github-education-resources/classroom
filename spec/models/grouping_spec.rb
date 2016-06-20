# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Group, type: :model do
  let(:organization) { GitHubFactory.create_owner_classroom_org }

  describe 'slug uniqueness' do
    it 'verifies that the slug is unique even if the titles are unique' do
      Grouping.create(title: 'Grouping 1', organization: organization)
      new_group = Grouping.create(title: 'grouping-1', organization: organization)

      expect { new_group.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
