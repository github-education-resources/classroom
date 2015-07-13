FactoryGirl.define do
  factory :assignment do
    title        { "#{Faker::Company.name} Assignment" }
    organization { FactoryGirl.create(:organization)   }
    creator      { organization.users.first            }
  end
end
