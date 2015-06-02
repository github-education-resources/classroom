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

  factory :organization do
    title      { "#{Faker::Company.name} Class" }
    github_id  { rand(1..1_000_000) }

    factory :organization_with_users do
      transient do
        users_count 5
      end

      after(:create) do |organization, evaluator|
        create_list(:user, evaluator.users_count, organizations: [organization])
      end
    end
  end

  factory :invitation do
    key      { SecureRandom.hex(16) }
    title    'Students'
    team_id  { rand(1..1_000_000) }

    organization { FactoryGirl.create(:organization_with_users) }
    user         { organization.users.first }
  end

  factory :assignment do
    title        { "#{Faker::Company.name} Assignment" }
    organization { FactoryGirl.create(:organization_with_users) }
  end
end
