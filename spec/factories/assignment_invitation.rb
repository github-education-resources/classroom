FactoryGirl.define do
  factory :assignment_invitation do
    factory :assignment_invitation_with_assignment do
      assignment { FactoryGirl.create(:assignment_with_organization) }
    end
  end
end
