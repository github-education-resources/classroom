# frozen_string_literal: true

require "rails_helper"

RSpec.describe Group::Creator, type: :model do
  let(:grouping) { create(:grouping) }
  let(:title)    { "#{Faker::Company.name} Team" }
end
