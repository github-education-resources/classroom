# frozen_string_literal: true
FactoryGirl.define do
  factory :grouping do
    title        { Faker::Company.name               }
    slug         { title.parameterize                }
    organization { FactoryGirl.create(:organization) }
  end
end
