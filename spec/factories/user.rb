# frozen_string_literal: true
require_relative '../support/vcr'

FactoryGirl.define do
  factory :user do
    uid    { rand(1..1_000_000) }
    token  { SecureRandom.hex(20) }

    factory :user_with_organizations do
      transient do
        organizations_count 5
      end

      after(:create) do |user, evaluator|
        create_list(:organization, evaluator.organizations_count, users: [user])
      end
    end
  end
end
