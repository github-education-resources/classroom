# frozen_string_literal: true

require "rails_helper"

RSpec.describe NullGitHubResource do
  subject { described_class.new }

  describe "#null?" do
    it "returns true" do
      expect(subject.null?).to be(true)
    end
  end
end
