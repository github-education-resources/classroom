# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grouping, type: :model do
  let(:organization) { create(:organization) }

  describe ".search" do
    let(:grouping) { create(:grouping) }

    before do
      expect(grouping).to_not be_nil
    end

    it "searches by id" do
      results = Grouping.search(grouping.id)
      expect(results.to_a).to include(grouping)
    end

    it "searches by slug" do
      results = Grouping.search(grouping.slug)
      expect(results.to_a).to include(grouping)
    end

    it "searches by title" do
      results = Grouping.search(grouping.title)
      expect(results.to_a).to include(grouping)
    end

    it "does not return the grouping when it shouldn't" do
      results = Grouping.search("spaghetto")
      expect(results.to_a).to_not include(grouping)
    end
  end

  describe "slug uniqueness" do
    it "verifies that the slug is unique even if the titles are unique" do
      create(:grouping, title: "Grouping 1", organization: organization)
      new_grouping = build(:grouping, title: "grouping-1", organization: organization)

      expect { new_grouping.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
