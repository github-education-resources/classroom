FactoryGirl.define do
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

  factory :owner_classroom_org, class: Organization do
    github_id { classroom_owner_github_org_id }
    title     { classroom_owner_github_org }

    users { [User.create(uid: classroom_owner_id, token: classroom_owner_github_token)] }
  end
end
