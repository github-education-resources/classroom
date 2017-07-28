# frozen_string_literal: true

require "rails_helper"

RSpec.describe Video::ShowView do
  subject do
    Video::ShowView.new(
      id: "12345",
      title: "Title",
      provider: "youtube",
      description: "description"
    )
  end

  describe "attributes" do
    it "responds to id" do
      expect(subject).to respond_to(:id)
    end

    it "responds to title" do
      expect(subject).to respond_to(:title)
    end

    it "responds to provider" do
      expect(subject).to respond_to(:provider)
    end

    it "responds to description" do
      expect(subject).to respond_to(:description)
    end
  end

  describe "#url" do
    it "returns correct url" do
      expect(subject.url).to eql("https://www.youtube.com/embed/#{subject.id}")
    end
  end
end
