# frozen_string_literal: true
FactoryGirl.define do
  factory :organization do
    title      { "#{Faker::Company.name} Class" }
    github_id  { rand(1..1_000_000) }

    transient do
      users_count 1
    end

    after(:build) do |organization, evaluator|
      create_list(:user, evaluator.users_count, organizations: [organization])
    end
  end
end
