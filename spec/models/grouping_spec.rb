# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grouping, type: :model do
  let(:organization) { create(:organization) }

  describe "slug uniqueness" do
    it "verifies that the slug is unique even if the titles are unique" do
      create(:grouping, title: "Grouping 1", organization: organization)
      new_grouping = build(:grouping, title: "grouping-1", organization: organization)

      expect { new_grouping.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
