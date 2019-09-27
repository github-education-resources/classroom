# frozen_string_literal: true

require "rails_helper"

describe GitHub::APIHeaders do
  subject { described_class }

  describe "#no_cache_no_store" do
    it "returns the 'Cache-Control' => 'no-cache, no-store'" do
      expect(described_class.no_cache_no_store).to eql("Cache-Control" => "no-cache, no-store")
    end
  end
end
