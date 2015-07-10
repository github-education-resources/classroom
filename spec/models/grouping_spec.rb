require 'rails_helper'

RSpec.describe Grouping, type: :model do
  it { should have_many(:groups).dependent(:destroy) }

  it { should belong_to(:organization) }

  it { should validate_presence_of(:organization) }

  it { should validate_presence_of(:title) }
  # https://github.com/thoughtbot/shoulda-matchers/issues/745
  # it { validate_uniqueness_of(:title).scoped_to(:organization) }
end
