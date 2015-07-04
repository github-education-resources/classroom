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

  # factory :classroom_owner, class: User do
  #   uid    { classroom_owner_id}
  #   token  { classroom_owner_github_token }
  # end

  factory :classroom_student, class: User do
    uid    { classroom_student_id }
    token  { classroom_student_github_token }
  end
end
