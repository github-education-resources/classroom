# frozen_string_literal: true

require "rails_helper"

RSpec.describe AvatarHelper, type: :helper do
  describe "#github_avatar_url" do
    it "returns the github avatar url with the proper size" do
      expect(github_avatar_url(1, 96)).to eq("https://avatars.githubusercontent.com/u/1?v=3&size=96")
    end
  end
end
