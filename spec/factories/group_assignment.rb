# frozen_string_literal: true
FactoryGirl.define do
  factory :group_assignment do
    title        { "#{Faker::Company.name} Group Assignment"                 }
    slug         { title.parameterize                                        }
    organization { FactoryGirl.create(:organization)                         }
    grouping     { FactoryGirl.create(:grouping, organization: organization) }
    creator      { organization.users.first                                  }
  end
end
