FactoryGirl.define do
  factory :assignment do
    title { "#{Faker::Company.name} Assignment" }
    assignment_invitation

    factory :assignment_with_organization do
      organization { FactoryGirl.create(:organization_with_users) }
    end
  end
end
