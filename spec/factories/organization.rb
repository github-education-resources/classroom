FactoryGirl.define do
  factory :organization do
    title      { "#{Faker::Company.name} Class" }
    github_id  { rand(1..1_000_000) }
    users      { [FactoryGirl.create(:user)] }
  end
end
