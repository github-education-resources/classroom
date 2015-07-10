FactoryGirl.define do
  factory :assignment do
    title { "#{Faker::Company.name} Assignment" }
    organization { FactoryGirl.create(:organization) }
  end
end
