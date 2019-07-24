# frozen_string_literal: true

require_relative "support/vcr"
require "securerandom"

FactoryBot.define do
  factory :assignment do
    organization

    title                 { "#{Faker::Company.name} Assignment" }
    slug                  { title.parameterize                  }
    creator               { organization.users.first            }
    assignment_invitation { build_assignment_invitation         }
  end

  factory :assignment_invitation do
    assignment
  end

  factory :invite_status do
    assignment_invitation
    user
  end

  factory :group_invite_status do
    group_assignment_invitation
    group
  end

  factory :assignment_repo do
    assignment
    user

    github_repo_id { rand(1..1_000_000) }
  end

  factory :deadline do
    assignment
    deadline_at { Time.zone.tomorrow }
  end

  factory :group_assignment do
    organization

    title    { "#{Faker::Company.name} Group Assignment"     }
    slug     { title.parameterize                            }
    grouping { create(:grouping, organization: organization) }
    creator  { organization.users.first                      }
    group_assignment_invitation { build_group_assignment_invitation }
  end

  factory :group_assignment_invitation do
    group_assignment
  end

  factory :grouping do
    organization

    title { Faker::Company.name }
    slug  { title.parameterize  }
  end

  factory :group_assignment_repo do
    group_assignment
    group
    github_repo_id { rand(1..1_000_000) }
  end
  factory :group do
    grouping

    title          { Faker::Team.name[0..39] }
    github_team_id { rand(1..1_000_000) }
  end

  factory :organization_webhook do
    github_organization_id { rand(1..1_000_000) }
  end

  factory :organization do
    organization_webhook

    title      { "#{Faker::Company.name} Class" }
    github_id  { organization_webhook.github_organization_id }

    transient do
      users_count 1
    end

    after(:build) do |organization, evaluator|
      create_list(:user, evaluator.users_count, organizations: [organization])
    end
  end

  factory :roster do
    identifier_name { "email" }

    after(:build) do |roster|
      roster.roster_entries << RosterEntry.create(identifier: "email")
    end
  end

  factory :roster_entry do
    roster
    identifier { "myemail@example.com" }
  end

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

  factory :lti_configuration do
    organization

    consumer_key { SecureRandom.uuid }
    shared_secret { SecureRandom.uuid }
    lms_link { "www.example.com" }
    lms_type { :other }
  end
end
