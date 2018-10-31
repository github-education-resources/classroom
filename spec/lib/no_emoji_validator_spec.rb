# frozen_string_literal: true

require "rails_helper"

class TestModel
  include ActiveModel::Model
  validates :title, no_emoji: true

  attr_accessor :title
end

RSpec.describe NoEmojiValidator do
  it "ignores nil values" do
    test_object = TestModel.new(title: nil)
    expect(test_object.valid?).to eq(true)
  end

  it "validates fields that contain emojis" do
    test_object = TestModel.new(title: "😃")
    expect(test_object.valid?).to eq(false)
    expect(test_object.errors.count).to eq(1)
    expect(test_object.errors.details[:title])
      .to eq([{ error: "title is not allowed to have emojis." }])
  end
end
