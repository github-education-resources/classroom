# frozen_string_literal: true
FactoryGirl.define do
  factory :student_identifier do
    organization            { FactoryGirl.create(:organization)            }
    user                    { organization.users.first                     }
    student_identifier_type { FactoryGirl.create(:student_identifier_type) }
    value                   { Faker::Lorem.word                            }
  end
end
