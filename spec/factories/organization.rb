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
end
