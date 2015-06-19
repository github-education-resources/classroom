FactoryGirl.define do
  factory :assignment_invitation_redeemer do
    assignment { FactoryGirl.create(:assignment_invitation_with_assignment).assignment }
    invitee    { FactoryGirl.create(:user) }

    initialize_with { AssignmentInvitationRedeemer.new(assignment, invitee) }
  end
end
