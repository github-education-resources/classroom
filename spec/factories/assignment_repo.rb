# frozen_string_literal: true
FactoryGirl.define do
  factory :assignment_repo do
    github_repo_id { rand(1..1_000_000) }

    assignment { FactoryGirl.create(:assignment) }
    user       { FactoryGirl.create(:user)       }
  end
end
