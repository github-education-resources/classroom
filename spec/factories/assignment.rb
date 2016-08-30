# frozen_string_literal: true
FactoryGirl.define do
  factory :assignment do
    title        { "#{Faker::Company.name} Assignment" }
    slug         { title.parameterize                  }
    organization { FactoryGirl.create(:organization)   }
    creator      { organization.users.first            }
  end
end
