# frozen_string_literal: true
FactoryGirl.define do
  factory :student_identifier_type do
    organization { FactoryGirl.create(:organization) }
    name         { Faker::Lorem.word                 }
    description  { Faker::Lorem.sentence             }
    content_type { 'text'                            }
  end
end
