# frozen_string_literal: true

require "rails_helper"

class TestModel
  include ActiveModel::Model
  validates :title, no_emoji: true

  attr_accessor :title
end

RSpec.describe NoEmojiValidator do
  context "title is nil" do
    let(:test_object) { TestModel.new(title: nil) }

    it "passes validation" do
      expect(test_object.valid?).to eq(true)
    end
  end

  context "title has no emojis" do
    let(:test_object) { TestModel.new(title: ":sparkles:") }

    it "passes validation" do
      expect(test_object.valid?).to eq(true)
    end
  end

  context "title has an emoji" do
    let(:test_object) { TestModel.new(title: "✨") }

    it "fails validation" do
      expect(test_object.valid?).to eq(false)
      expect(test_object.errors.count).to eq(1)
      expect(test_object.errors.details[:title])
        .to eq([{ error: "title cannot contain emojis." }])
    end
  end
end
