FactoryGirl.define do
  factory :group_assignment do
    title        { "#{Faker::Company.name} Assignment"                            }
    organization { FactoryGirl.create(:organization)                              }
    grouping     { Grouping.create(title: 'Grouping', organization: organization) }
    creator      { organization.users.first                                       }
  end
end
