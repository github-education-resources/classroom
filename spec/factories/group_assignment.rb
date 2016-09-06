# frozen_string_literal: true
FactoryGirl.define do
  factory :group_assignment do
    title        { "#{Faker::Company.name} Group Assignment"                      }
    slug         { Faker::Company.name.parameterize                               }
    organization { FactoryGirl.create(:organization)                              }
    grouping     { Grouping.create(title: 'Grouping', organization: organization) }
    creator      { organization.users.first                                       }
  end
end
